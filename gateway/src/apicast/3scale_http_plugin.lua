local cjson = require('cjson')
local configuration_store = require('apicast.configuration_store')
local remote_v2_configuration_loader = require('apicast.configuration_loader.remote_v2')
local Configuration = require('apicast.configuration')
local Proxy = require('apicast.proxy')
local ngx_re = require('ngx.re')

local tostring = tostring

local _M = {
    configuration = configuration_store.new()
}

local environment = 'production'
local version = 'latest'

local function fetch_service(store, service_id, system_endpoint)
    local remote_v2 = remote_v2_configuration_loader.new(system_endpoint)
    local config = remote_v2:config({ id = service_id }, environment, version)
    if not config then return end

    store:store(Configuration.new{ services = { config.content }, oidc = { config.oidc }})

    return store:find_by_id(service_id)
end

local function get_service(store, payload)
    local service_id = tostring(payload.service_id)
    local service = store:find_by_id(service_id)

    if not service then
        service = fetch_service(store, service_id, payload.system_endpoint)
    end

    return service
end

local function rewrite_request(request)
    local method = assert(ngx['HTTP_' .. request.method])
    local uri = assert(ngx_re.split(request.path, [[\?]], 'oj', nil, 2))

    ngx.req.set_method(method)
    ngx.req.set_uri(uri[1] or '')
    ngx.req.set_uri_args(uri[2] or '')

    for header, value in pairs(request.headers) do
        ngx.req.set_header(header, value)
    end
end

local function get_payload()
    ngx.req.read_body()

    -- TODO: detect content type
    local body = ngx.req.get_body_data()

    return cjson.decode(body)
end

function _M.auth()
    local configuration = _M.configuration
    local payload = get_payload()
    local service = get_service(configuration, payload)

    rewrite_request(payload.http_request)

    local context = {}
    local proxy = Proxy.new(configuration)

    proxy.http_ng_backend = require('resty.http_ng.backend.resty')
    proxy:rewrite(service, context)
    proxy:access(service, context.usage, context.credentials, context.ttl)

    ngx.print('OK')
end

function _M.report()

end


return _M
