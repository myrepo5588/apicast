local policy = require('apicast.policy')
local Usage = require('apicast.usage')
local limits_loader = require('apicast.threescale.limits_loader')
local metrics_hierarchy_loader = require('apicast.threescale.metrics_hierarchy_loader')
local threescale_system_client = require('apicast.threescale.system_client')
local http_ng_client = require('resty.http_ng').new()
local http_ng_ngx = require('resty.http_ng.backend.ngx')
local backend_client = require('apicast.backend_client')
local resty_lrucache = require('resty.lrucache')
local limit_traffic = require "resty.limit.traffic"
local semaphore = require "ngx.semaphore"

local assert = assert
local ipairs = ipairs
local pairs = pairs
local insert = table.insert
local format = string.format
local getn = table.getn

local _M = policy.new('3scale rate limit policy')

local new = _M.new

local default_ttl_credentials_seconds = 60

local semaphore_metrics_hierarchy = semaphore.new(1)
local semaphore_limits = semaphore.new(1)

-- TODO: avoid duplicating this. It's also in proxy.lua
-- Converts a usage to the format expected by the 3scale backend client.
local function format_usage(usage)
  local res = {}

  local usage_metrics = usage.metrics
  local usage_deltas = usage.deltas

  for _, metric in ipairs(usage_metrics) do
    local delta = usage_deltas[metric]
    res['usage[' .. metric .. ']'] = delta
  end

  return res
end

-- TODO: avoid duplicating this. It's also in proxy.lua
local function error_limits_exceeded(service)
  ngx.log(ngx.INFO, 'limits exceeded for service ', service.id)
  ngx.var.cached_key = nil
  ngx.status = service.limits_exceeded_status
  ngx.header.content_type = service.limits_exceeded_headers
  ngx.print(service.error_limits_exceeded)
  return ngx.exit(ngx.HTTP_OK)
end

local function get_limiters(threescale_portal_endpoint, access_token, service_id)
  local threescale_client = threescale_system_client.new(
    threescale_portal_endpoint, access_token, http_ng_client)

  return limits_loader.get_limits(service_id, threescale_client, 'limiter')
end

local function get_metrics_hierarchy(threescale_portal_endpoint, access_token, service_id)
  local threescale_client = threescale_system_client.new(
    threescale_portal_endpoint, access_token, http_ng_client)

  return metrics_hierarchy_loader.get_metrics_hierarchy(service_id, threescale_client)
end

local function select_limiters(limiters, plan, metrics)
  local res = {}

  for _, metric in ipairs(metrics) do
    local metric_limiters = limiters[plan][metric] or {}

    for _, limiter in pairs(metric_limiters) do
      insert(res, limiter)
    end
  end

  return res
end

local function limiter_key_for_user_key(service_id, user_key)
  return format("service_id:%s,user_key:%s", service_id, user_key)
end

local function usage_with_parents_added(usage, metrics_hierarchy)
  local res = Usage.new()

  for metric, value in pairs(usage.deltas) do
    res:add(metric, value)

    local parent_metric = metrics_hierarchy.metric
    if parent_metric then
      res:add(parent_metric, value)
    end
  end

  return res
end

local function metrics_hierarchy_from_config(config)
  if not config.metrics_hierarchy then return nil end

  local res = {}

  for _, metric_relationship in ipairs(config.metrics_hierarchy) do
    res[metric_relationship.child] = metric_relationship.parent
  end

  return res
end

local function limiters_from_config_plans(config)
  if not config.limits then return nil end

  local limits = {}

  for _, limit in pairs(config.limits) do
    local limit = {
      plan = limit.plan,
      metric = limit.metric,
      period = limit.period,
      value = limit.value
    }
    insert(limits, limit)
  end

  return limits_loader.get_resty_limits(limits, 'limiter')
end

function _M.new(config)
  local self = new(config)
  self.threescale_portal_endpoint = config.threescale_portal_endpoint
  self.access_token = config.access_token
  self.ttl_credentials_seconds = config.ttl_credentials_seconds or
      default_ttl_credentials_seconds

  self.metrics_hierarchy = metrics_hierarchy_from_config(config)
  self.limiters = limiters_from_config_plans(config)

  -- TODO: assume user_key for now
  self.known_user_keys = resty_lrucache.new(10000)
  return self
end

function _M:rewrite(context)
  -- TODO: I think this could go in access() too. Does not really matter.
  -- Can't do network requests in .new()

  semaphore_metrics_hierarchy:wait(10)

  if not self.metrics_hierarchy then
    self.metrics_hierarchy = get_metrics_hierarchy(
      self.threescale_portal_endpoint, self.access_token, context.service.id)
  end

  semaphore_metrics_hierarchy:post(1)

  semaphore_limits:wait(10)

  if not self.limiters then
    self.limiters = get_limiters(
      self.threescale_portal_endpoint, self.access_token, context.service.id)
  end

  semaphore_limits:post(1)

  -- TODO: metric_hierarchy and limiters could be nil here if the request
  -- fails or takes too much.
end

function _M:access(context)
  -- TODO: add support for all the cred methods backend support.
  -- Assume user_key for now.

  -- TODO: fix case where the metrics is increase by > 1.

  local backend = assert(backend_client:new(context.service, http_ng_ngx), 'missing backend')
  local formatted_usage = format_usage(context.usage)

  local cached_auth = self.known_user_keys:get(context.credentials.user_key)

  local creds_ok
  local plan_name

  if cached_auth and cached_auth.valid then
    creds_ok = true
    plan_name = cached_auth.plan
  end

  -- TODO: check all possible backend answers.
  -- Possible backend answers:
  -- if status == 200 => Creds OK.
  -- if status == 409 and rejection_reason == limits_exceeded => Creds OK.
  -- Creds invalid for everything else.

  local usage_with_parents = usage_with_parents_added(context.usage, self.metrics_hierarchy)
  local metrics = {}

  for metric, _ in pairs(usage_with_parents.deltas) do
    insert(metrics, metric)
  end

  if not cached_auth then
    local backend_res = backend:authorize(formatted_usage, context.credentials)

    if backend_res.status == 200 then
      local re_match, err = ngx.re.match(backend_res.body, "<plan>(\\w+)</plan>", "oj")

      -- TODO: matching errors
      plan_name = re_match[1]

      self.known_user_keys:set(
        context.credentials.user_key,
        { valid = true, plan = plan_name },
        self.ttl_credentials_seconds
      )

      creds_ok = true
    else
      -- TODO: return error like in Apicast policy
    end
  end

  if creds_ok then
    local limiters = select_limiters(self.limiters, plan_name, metrics)
    local limiter_key = limiter_key_for_user_key(context.service.id, context.credentials.user_key)

    local limiter_keys = {}
    for i=1, getn(limiters) do
      insert(limiter_keys, limiter_key)
    end

    local delay, err = limit_traffic.combine(limiters, limiter_keys, {})

    if not delay then
      if err == "rejected" then
        return error_limits_exceeded(context.service)
      else
        -- TODO: error while applying limits
      end
    end
  else
    -- TODO: return error like in Apicast policy
  end

  context.authorization_done = true
end

return _M
