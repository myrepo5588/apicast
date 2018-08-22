local configuration_parser = require('apicast.configuration_parser')
local cjson = require('cjson')

local ipairs = ipairs

local _M = {}


local empty = {}

local function array()
    return setmetatable({}, cjson.empty_array_mt)
end

local discovery = require('resty.oidc.discovery').new()

inspect = require('inspect')
local function load_oidc(issuer)
    local config = discovery:openid_configuration(issuer)

    ngx.log(ngx.STDERR, ' GOT CONFIG: ', inspect(config))

    local keys = discovery:jwk(config)

    ngx.log(ngx.STDERR, ' GOT KEYS: ', inspect(keys))

    return { issuer = issuer, config = config, keys = keys }
end

function _M.call(contents)
    local config = configuration_parser.decode(contents)

    if config then
        local oidc = config.oidc or array()

        for i,service in ipairs(config.services or empty) do
            oidc[i] = load_oidc(service.proxy.oidc_issuer_endpoint)
        end

        config.oidc = oidc

        return cjson.encode(config)
    else
        return contents
    end
end

return _M
