local setmetatable = setmetatable
local random = require 'resty.random'
local ts = require 'threescale_utils'
local cjson = require 'cjson'
local backend_client = require ('backend_client')
local get_token = require 'oauth.apicast_oauth.get_token'

local _M = {
  _VERSION = '0.1'
}

local mt = { __index = _M }

-- Required params for each grant type and response type.
_M.params = {
  grant_type = {
    ['authorization_code'] = {'client_id','redirect_uri','code'},
    ['password'] = {'client_id','client_secret','username','password'},
    ['client_credentials'] = {'client_id','client_secret'}
  },
  response_type = {
    ['code'] = {'client_id','redirect_uri'},
    ['token'] = {'client_id','redirect_uri'}
  }
}

function _M.new()
  return setmetatable(
    {
      get_token = get_token.call
    }, mt)
end

function _M.transform_credentials(_, credentials)
  return credentials
end

function _M.respond_and_exit(status, body, headers)
  -- TODO: is there a better way to populate the response headers?..
  if headers then
    for name,value in pairs(headers) do
      ngx.header[name] = value
    end
  end

  ngx.status = status
  ngx.print(body)
  ngx.exit(ngx.HTTP_OK)
end

function _M.respond_with_error(status, message)

  --TODO: as per the RFC (https://tools.ietf.org/html/rfc6749#section-5.2) return WWW-Authenticate response header if 401
  local headers = {
    ['Content-Type'] = 'application/json;charset=UTF-8'
  }
  local err_msg = { error = message }
  local body = cjson.encode(err_msg)
  _M.respond_and_exit(status, body, headers)
end

-- TOOD: Split error conditions up further to decide when we should respond with error and when we should redirect_with error
function _M.redirect_with_error(url, error, state)
  ngx.header.content_type = "application/x-www-form-urlencoded"
  return ngx.redirect(url,"?error=",error.error,"&error_description=",error.error_description,"&state=",state)
end

function _M.authorize_check_params(params)
  local response_type = params.response_type
  local required_params = _M.params.response_type
  if not response_type then return false, 'invalid_request' end
  if not required_params[response_type] then return false, 'unsupported_response_type' end

  for _,v in ipairs(required_params[response_type]) do
    if not params[v] then
      return false, 'invalid_request'
    end
  end

  return true
end

function _M.check_credentials(service, params)
  local backend = backend_client:new(service)

  local args = {
      app_id = params.client_id,
      app_key = params.client_secret,
      redirect_uri = params.redirect_uri
    }

  local res = backend:authorize(args)

  return res.status == 200
end

-- returns a unique string for the client_id. it will be short lived
local function nonce(client_id)
  return ts.sha1_digest(tostring(random.bytes(20, true)) .. "#login:" .. client_id)
end

local function generate_access_token(client_id)
  return ts.sha1_digest(tostring(random.bytes(20, true)) .. client_id)
end

local function persist_nonce(service_id, params)
  -- State value shared between client and gateway
  local client_state = params.state

  -- State value that will be shared between gateway and authorization server
  local n = nonce(params.client_id)

  -- Pre-generated access token
  --TODO: Check if we can just generate token when we need it later
  local pre_token = generate_access_token(params.client_id)

  local redis_key = service_id.."#tmp_data:"..n
  local client_data = {
    client_id = params.client_id,
    redirect_uri = params.redirect_uri,
    plan_id = params.scope,
    access_token = pre_token,
    state = client_state
  }

  local redis = ts.connect_redis()

  if redis then
    redis:hmset(redis_key, client_data )
    ts.release_redis(redis)
  end

  -- Overwrite state to nonce value to share state between gateway and auth server
  params.state = n
end

-- Generate authorization code from params
local function generate_code(client_data)
  return ts.sha1_digest(tostring(random.bytes(20, true)) .. "#code:" .. tostring(client_data.client_id))
end

local function persist_code(client_data, code)
  local ok, err
  local redis = ts.connect_redis()

  if redis then
    ok, err = redis:hmset("c:".. code, {
      client_id = client_data.client_id,
      client_secret = client_data.secret_id,
      redirect_uri = client_data.redirect_uri,
      access_token = client_data.access_token,
      code = code
    })

    if ok then
      return redis:expire("c:".. code, 60 * 10) -- code expires in 10 mins
    else
      return ok, err
    end

    ts.release_redis(redis)
  end
end

function _M.check_state(state)
  redis = ts.connect_redis()

  if redis then
    local tmp_data = ngx.ctx.service.id.."#tmp_data"..state
    ok, err = redis:hgetall(tmp_data)
    redis:del(tmp_data)
    
    if not ok then
      return ok, err
    end

    client_data = redis:array_to_hash(ok)
    ts.release_redis(redis)
  end
end

function _M.authorize(service)
  local params = ngx.req.get_uri_args()

  local ok, err = _M.authorize_check_params(params)
  if not ok then
    _M.respond_with_error(400, err)
    return
  end

  ok = _M.check_credentials(service, params)
  if not ok then
    _M.respond_with_error(401, 'invalid_client')
    return
  end

  persist_nonce(service.id, params)

  local args = ts.build_query(params)
  local login_url = service.oauth_login_url or error('missing oauth login url')

  ngx.header.content_type = "application/x-www-form-urlencoded"
  return ngx.redirect(login_url .. "?" .. args)
end

function _M.callback()
  local ok, err
  local client_data

  local params = ngx.req.get_uri_args()

  if not params.state then
    _M.respond_with_error(400, "invalid_request")
    return
  end
  
  ok, err = _M.check_state(params.state)
  
  if not ok then 
  -- TODO: Add debug message for ngx
  -- TODO: where do we get the redirect_uri from unless the Authorization passes it back to us?
    _M.respond_with_error(400, 'invalid_state')
    return
  end

  local code = generate_code(client_data)
  ok, err = persist_code(client_data, params, code)

  if not ok then
    _M.redirect_with_error(client_data.redirect_uri, err, client_data.state)
    return   
  end

  ngx.header.content_type = "application/x-www-form-urlencoded"
  return ngx.redirect( client_data.redirect_uri .. "?code="..code.."&state=" .. (client_data.state or ""))

end

return _M
