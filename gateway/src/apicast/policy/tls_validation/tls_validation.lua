-- This is a tls_validation description.

local policy = require('apicast.policy')
local ssl = require('ngx.ssl')
local _M = policy.new('tls_validation')
local X509_STORE = require('resty.openssl.x509.store')
local X509 = require('resty.openssl.x509')

local ipairs = ipairs
local tostring = tostring

local debug = ngx.config.debug

local new = _M.new
--- Initialize a tls_validation
-- @tparam[opt] table config Policy configuration.
function _M.new(config)
  local self = new(config)
  local store = X509_STORE.new()

  for _,certificate in ipairs(config and config.whitelist or {}) do
    local cert, err = X509.parse_pem_cert(certificate.pem_certificate) -- TODO: handle errors

    if cert then
      store:add_cert(cert)

      if debug then
        ngx.log(ngx.DEBUG, 'adding certificate to the tls validation ', tostring(cert:subject_name()), ' SHA1: ', cert:hexdigest('SHA1'))
      end
    else
      ngx.log(ngx.WARN, 'error whitelisting certificate, err: ', err)

      if debug then
        ngx.log(ngx.DEBUG, 'certificate: ', certificate.pem_certificate)
      end
    end
  end

  self.x509_store = store
  self.error_status = config and config.error_status or 400

  return self
end

function _M:access()
  local cert = X509.parse_pem_cert(ngx.var.ssl_client_raw_cert)
  local store = self.x509_store

  local ok, err = store:validate_cert(cert)
  if not ok then
    ngx.status = self.error_status
    ngx.say(err)
    return ngx.exit(ngx.status)
  end
end

return _M
