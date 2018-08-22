local setmetatable = setmetatable
local type = type
local len = string.len
local assert = assert

local resty_url = require 'resty.url'
local http_ng = require "resty.http_ng"
local resty_env = require 'resty.env'
local Mime = require 'resty.mime'
local cjson = require('cjson')
local jwk = require('resty.oidc.jwk')

local oidc_log_level = ngx[string.upper(resty_env.value('APICAST_OIDC_LOG_LEVEL') or 'err')] or ngx.ERR

local _M = { }

local mt = { __index = _M }

local function openid_configuration_url(endpoint)
    if endpoint and type(endpoint) == 'string' and len(endpoint) > 0 then
        return resty_url.join(endpoint, '.well-known/openid-configuration')
    end
end

local function mime_type(content_type)
    return Mime.new(content_type).media_type
end

local function decode_json(response)
    return mime_type(response.headers.content_type) == 'application/json' and cjson.decode(response.body)
end


function _M.new(http_backend)
    local http_client = http_ng.new{
        backend = http_backend,
        options = {
            ssl = { verify = resty_env.enabled('OPENSSL_VERIFY') }
        }
    }

    local self = { http_client = http_client }

    return setmetatable(self, mt)
end

function _M:openid_configuration(endpoint)
    local http_client = self.http_client

    if not http_client then
        return nil, 'not initialized'
    end

    local uri = openid_configuration_url(endpoint)

    if not uri then
        return nil, 'no OIDC endpoint'
    end

    local res = http_client.get(uri)

    if res.status ~= 200 then
        ngx.log(oidc_log_level, 'failed to get OIDC Provider from ', uri, ' status: ', res.status, ' body: ', res.body)
        return nil, 'could not get OpenID Connect configuration'
    end

    local config = decode_json(res)

    if not config then
        ngx.log(oidc_log_level, 'invalid OIDC Provider, expected application/json got:  ', res.headers.content_type, ' body: ', res.body)
        return nil, 'invalid JSON'
    end

    return config
end

function _M:jwk(configuration)
    local http_client = self.http_client

    if not http_client then
        return nil, 'not initialized'
    end

    if not configuration then
        return nil, 'm'
    end

    local jwks_uri = assert(configuration, 'missing configuration').jwks_uri

    local res = http_client.get(jwks_uri)

    if res.status == 200 then
        return jwk.convert_keys(decode_json(res))
    else
        return nil, 'invalid response'
    end
end

return _M
