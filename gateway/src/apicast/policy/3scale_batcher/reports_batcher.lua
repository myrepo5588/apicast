local keys_helper = require('apicast.policy.3scale_batcher.keys_helper')

local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local insert = table.insert
local resty_lock = require 'resty.lock'
local semaphore = require "ngx.semaphore"

local _M = {}

local mt = { __index = _M }

local lock_timeout = 10

-- Note: storage needs to implement shdict interface.
function _M.new(storage, lock_shdict_name)
  local self = setmetatable({}, mt)
  --self.storage = storage
  self.storage = {}

  self.lock_shdict_name = lock_shdict_name

  local sema, err = semaphore.new(1)
  if not sema then
    ngx.log(ngx.ERR, "create semaphore failed: ", err)
  end

  self.storage_semaphore = sema

  return self
end

-- Note: When the lock cannot be acquired, the report will be lost.
-- The timeout is high, that means that if it could not be acquired, there's
-- probably a problem in the system.
-- TODO: Find a solution for this.
function _M:add(service_id, credentials, usage)
--[[
  local deltas = usage.deltas

  local lock, new_lock_err = resty_lock:new(self.lock_shdict_name, { timeout = lock_timeout })
  if not lock then
    ngx.log(ngx.ERR, 'failed to create lock: ', new_lock_err)
    return
  end

  local elapsed, lock_err = lock:lock(service_id)
  if not elapsed then
    ngx.log("failed to acquire the lock: ", lock_err)
    return
  end

  for _, metric in ipairs(usage.metrics) do
    local key = keys_helper.key_for_batched_report(service_id, credentials, metric)
    self.storage:incr(key, deltas[metric], 0)
  end

  local ok, unlock_err = lock:unlock()
  if not ok then
    ngx.log(ngx.ERR, 'failed to unlock: ', unlock_err)
    return
  end
--]]
  local deltas = usage.deltas

  local wait_ok, wait_err = self.storage_semaphore:wait(lock_timeout)

  if not wait_ok then
    ngx.log(ngx.ERR, "failed to acquire semaphore resource: ", wait_err)
    return
  end

  for _, metric in ipairs(usage.metrics) do
    local key = keys_helper.key_for_batched_report(service_id, credentials, metric)
    self.storage[service_id] = self.storage[service_id] or {}
    self.storage[service_id][key] = (self.storage[service_id][key] or 0) + deltas[metric]
  end

  self.storage_semaphore:post(1)
end

function _M:get_all(service_id)
--[[
  local cached_reports = {}

  local cached_report_keys = self.storage:get_keys()

  local lock, new_lock_err = resty_lock:new(self.lock_shdict_name, { timeout = lock_timeout } )
  if not lock then
    ngx.log(ngx.ERR, 'failed to create lock: ', new_lock_err)
    return {}
  end

  local elapsed, lock_err = lock:lock(service_id)
  if not elapsed then
    ngx.log(ngx.ERR, "failed to acquire the lock: ", lock_err)
    return {}
  end

  for _, key in ipairs(cached_report_keys) do
    local value = self.storage:get(key)

    local report = keys_helper.report_from_key_batched_report(key, value)

    if value and value > 0 and report.service_id == service_id then
      insert(cached_reports, report)
      self.storage:delete(key)
    end
  end

  local ok, unlock_err = lock:unlock()
  if not ok then
    ngx.log(ngx.ERR, 'failed to unlock: ', unlock_err)
    return
  end

  return cached_reports
--]]

  local cached_reports = {}

  local wait_ok, wait_err = self.storage_semaphore:wait(lock_timeout)

  if not wait_ok then
    ngx.log("failed to acquire semaphore resource: ", wait_err)
    return {}
  end

  for key, value in pairs(self.storage[service_id] or {}) do
    local report = keys_helper.report_from_key_batched_report(key, value)
    if value and value > 0 and report.service_id == service_id then
      insert(cached_reports, report)
    end
  end

  self.storage[service_id] = nil

  self.storage_semaphore:post(1)

  return cached_reports
end

return _M
