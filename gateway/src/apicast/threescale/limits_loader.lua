local resty_limit_count = require('resty.limit.count')

local ipairs = ipairs
local pairs = pairs
local insert = table.insert

local _M = {}

local function get_plans(service_id, threescale_client)
  local res = {}

  local plans = threescale_client:get_plans_of_service(service_id).plans

  for _, v in ipairs(plans) do
    res[v.application_plan.id] = v.application_plan.name
  end

  return res
end

local function get_limits_of_plan(plan_id, threescale_client)
  local res = {}

  local limits = threescale_client:get_limits_of_plan(plan_id).limits

  for _, v in ipairs(limits) do
    local metric_id = v.limit.metric_id
    local period = v.limit.period
    local value = v.limit.value

    insert(res, { metric_id = metric_id, period = period, value = value })
  end

  return res
end

local function get_metric_names(service_id, threescale_client)
  local res = {}

  local metrics = threescale_client:get_metrics_of_service(service_id).metrics

  for _, v in ipairs(metrics) do
    local id = v.metric.id
    local name = v.metric.system_name
    res[id] = name
  end

  return res
end

local seconds_from_granularity = {
  minute = 60,
  hour = 60*60,
  day = 24*60*60,
  week = 7*24*60*60,
  month = 30*24*60*60,
  year = 365*24*60*60,
  infinity = -1 -- TODO: check what to put here so keys do not expire
}

local function resty_limit(limit, shdict_key)
  local seconds = seconds_from_granularity[limit.period]
  return resty_limit_count.new(shdict_key, limit.value, seconds)
end

function _M.get_limits(service_id, threescale_client, shdict_key)
  local res = {}

  local metric_names = get_metric_names(service_id, threescale_client)

  local plans = get_plans(service_id, threescale_client)

  for plan_id, plan_name in pairs(plans) do
    res[plan_name] = {}

    local limits = get_limits_of_plan(plan_id, threescale_client)

    for _, limit in ipairs(limits) do
      local metric_name = metric_names[limit.metric_id]
      res[plan_name][metric_name] = res[plan_name][metric_name] or {}
      res[plan_name][metric_name][limit.period] = resty_limit(limit, shdict_key)
    end
  end

  return res
end

function _M.get_resty_limits(limits, shdict_key)
  local res = {}

  for _, limit in ipairs(limits) do
    res[limit.plan] = res[limit.plan] or {}
    res[limit.plan][limit.metric] = res[limit.plan][limit.metric] or {}
    res[limit.plan][limit.metric][limit.period] = resty_limit(limit, shdict_key)
  end

  return res
end

return _M
