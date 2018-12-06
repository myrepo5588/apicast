-- This is a tls_validation description.

local policy = require('apicast.policy')
local ssl = require('ngx.ssl')
local _M = policy.new('tls_validation')

local new = _M.new
--- Initialize a tls_validation
-- @tparam[opt] table config Policy configuration.
function _M.new(config)
  local self = new(config)
  return self
end

function _M:access(context)
  ngx.log(ngx.STDERR, tostring(context))

  local pem_cert, err = ssl.parse_pem_cert(ngx.var.ssl_client_raw_cert)
  require('resty.repl').start()
end

return _M
