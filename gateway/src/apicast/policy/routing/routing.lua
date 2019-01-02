local ipairs = ipairs
local tab_insert = table.insert
local tab_new = require('resty.core.base').new_tab
local error = error
local match = ngx.re.match

local Upstream = require('apicast.upstream')
local balancer = require('apicast.balancer')

local _M = require('apicast.policy').new('Routing policy')

local new = _M.new

-- Parses the urls in the config so we do not have to do it on each request.
local function init_config(config)
  if not config or not config.rules then return tab_new(0, 0) end

  local res = tab_new(#config.rules, 0)

  for _, rule in ipairs(config.rules) do
    local upstream, err = Upstream.new(rule.url)

    if upstream then
      tab_insert(
        res,
        {
          entity = rule.entity,
          entity_value = rule.entity_value,
          op = rule.op,
          value = rule.value,
          url = rule.url
        }
      )
    else
      ngx.log(ngx.WARN, 'failed to initialize upstream from url: ', rule.url, ' err: ', err)
    end
  end

  return res
end

function _M.new(config)
  local self = new(config)
  self.rules = init_config(config)
  return self
end

local function evaluate_condition(left, op, right)
  if op == "==" then
    return left == right
  elseif op == "!=" then
    return left ~= right
  elseif op == "matches" then
    return match(left, right)
  else
    error('Operation not implemented: ' .. op)
  end
end

local function left_operand_value(entity, entity_value, context)
  if entity == 'path' then
    return ngx.var.uri
  elseif entity == 'header' then
    return ngx.req.get_headers()[entity_value]
  elseif entity == 'query_arg' then
    return ngx.req.get_uri_args()[entity_value]
  elseif entity == 'jwt_claim' then
    -- Note: In order to be able to match a JWT claim, this policy expects
    -- another one to validate the token and include it in the context.
    return (context.jwt and context.jwt[entity_value]) or nil
  else
    error('Entity to be matched not supported: ' .. entity)
  end
end

local function matched_upstream(rules, context)
  for _, rule in ipairs(rules) do
    local left_operand_val = left_operand_value(
      rule.entity, rule.entity_value, context
    )

    local cond_is_true = evaluate_condition(
      left_operand_val, rule.op, rule.value
    )

    if cond_is_true then
      return Upstream.new(rule.url)
    end
  end

  return nil
end

function _M:content(context)
  local upstream = matched_upstream(self.rules, context)

  if upstream then
    upstream:call(context)
  else
    return nil, 'no upstream'
  end
end

_M.balancer = balancer.call

return _M
