local ipairs = ipairs
local pairs = pairs

local _M = {}

-- Returns table where the keys are metric names and the values the parent name
function _M.get_metrics_hierarchy(service_id, threescale_client)
  local res = {}

  local metrics = threescale_client:get_metrics_of_service(service_id).metrics

  local metric_ids = {}

  for _, v in ipairs(metrics) do
    local metric_name = v.metric.system_name
    local metric_id = v.metric.id

    metric_ids[metric_id] = metric_name
  end

  for metric_id, metric_name in pairs(metric_ids) do
    local children = threescale_client:get_children_of_metric(service_id, metric_id).methods

    for _, v in ipairs(children) do
      local child_metric_name = v.method.system_name
      res[child_metric_name] = metric_name
    end
  end

  return res
end

return _M
