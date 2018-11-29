local _M = require('apicast.policy').new('Upstream (JWT claims)', '1.0.0')

local balancer = require('apicast.balancer')
local Upstream = require('apicast.upstream')

local ipairs = ipairs
local match = ngx.re.match
local tab_insert = table.insert
local tab_new = require('resty.core.base').new_tab

local new = _M.new

-- Parses the urls in the config so we do not have to do it on each request.
local function init_config(config)
  if not config or not config.rules then return tab_new(0, 0) end

  local res = tab_new(#config.rules, 0)

  for _, rule in ipairs(config.rules) do
    local upstream, err = Upstream.new(rule.url)

    if upstream then
      tab_insert(res, { jwt_claim = rule.jwt_claim, regex = rule.regex, url = rule.url })
    else
      ngx.log(ngx.WARN, 'failed to initialize upstream from url: ', rule.url, ' err: ', err)
    end
  end

  return res
end

local function matching_upstream(jwt, rules)
  if jwt then
    for _, rule in ipairs(rules) do
      local jwt_claim_val = rule.jwt_claim and jwt[rule.jwt_claim]

      if jwt_claim_val then
        if match(jwt_claim_val, rule.regex) then
          ngx.log(ngx.DEBUG, 'The upstream (JWT claim) policy matched a rule')
          return Upstream.new(rule.url)
        end
      end
    end
  end

  return nil
end

function _M.new(config)
  local self = new(config)
  self.rules = init_config(config)
  return self
end

function _M:content(context)
  -- This policy needs to be placed before APIcast, otherwise, the request
  -- would be proxied before this phase runs.
  -- However, that means that we can't find the matching upstream on the
  -- rewrite phase, because APIcast decodes and verifies the token in that
  -- phase. That's why it is done here instead of in the rewrite phase, which
  -- would be more "correct".
  local upstream = matching_upstream(context.jwt, self.rules)

  if upstream then
    upstream:call(context)
  else
    return nil, 'no upstream'
  end
end

_M.balancer = balancer.call

return _M
