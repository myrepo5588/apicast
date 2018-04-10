local cjson = require('cjson')
local setmetatable = setmetatable

local _M = {}

local mt = { __index = _M }

local function make_request(http_ng_client, url)
  local request = {
    method = 'GET',
    url = url,
    options = { ssl = { verify = false } }
  }

  local resp_body = http_ng_client.backend:send(request).body

  return cjson.decode(resp_body)
end

function _M.new(threescale_portal_endpoint, access_token, http_ng_client)
  local self = setmetatable({}, mt)
  self.threescale_portal_endpoint = threescale_portal_endpoint
  self.access_token = access_token
  self.http_ng_client = http_ng_client
  return self
end

function _M:get_plans_of_service(service_id)
  local url = self.threescale_portal_endpoint ..
      "/admin/api/services/" ..
      service_id ..
      "/application_plans.json" ..
      "?access_token=" ..
      self.access_token

  local res = make_request(self.http_ng_client, url)

  return res
end

function _M:get_limits_of_plan(plan_id)
  local url = self.threescale_portal_endpoint ..
      "/admin/api/application_plans/" ..
      plan_id ..
      "/limits.json" ..
      "?access_token=" ..
      self.access_token

  local res = make_request(self.http_ng_client, url)

  return res
end

function _M:get_metrics_of_service(service_id)
  local url = self.threescale_portal_endpoint ..
      "/admin/api/services/" ..
      service_id ..
      "/metrics.json?" ..
      "?access_token=" ..
      self.access_token

  local res = make_request(self.http_ng_client, url)

  return res
end

function _M:get_children_of_metric(service_id, metric_id)
  local url = self.threescale_portal_endpoint ..
      "/admin/api/services/" ..
      service_id ..
      "/metrics/" ..
      metric_id ..
      "/methods.json" ..
      "?access_token=" ..
      self.access_token

  local res = make_request(self.http_ng_client, url)

  return res
end

-- TODO
function _M:get_plan_of_application(app_id)
  local url = ""
  local res = make_request(self.http_ng_client, url)
  return res
end

return _M
