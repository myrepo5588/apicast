local base = require('resty.openssl.base')
local BIO = require('resty.openssl.bio')
local ffi = require('ffi')

ffi.cdef([[
int OPENSSL_sk_num(const OPENSSL_STACK *);
void *OPENSSL_sk_value(const OPENSSL_STACK *, int);

X509 *PEM_read_bio_X509(BIO *bp, X509 **x, pem_password_cb *cb, void *u);

]])

local C = ffi.C
local ffi_assert = base.ffi_assert
local assert = assert
local _M = {}

function _M.parse_pem_cert(str)
  local bio = BIO.new()

  assert(bio:write(str))

  return ffi_assert(C.PEM_read_bio_X509(bio.cdata, nil, nil, nil))
end

return _M
