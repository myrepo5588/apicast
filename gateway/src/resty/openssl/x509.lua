local base = require('resty.openssl.base')
local BIO = require('resty.openssl.bio')
local X509_NAME = require('resty.openssl.x509.name')
local ffi = require('ffi')

ffi.cdef([[
int OPENSSL_sk_num(const OPENSSL_STACK *);
void *OPENSSL_sk_value(const OPENSSL_STACK *, int);
void *OPENSSL_sk_shift(OPENSSL_STACK *st);

X509 *PEM_read_bio_X509(BIO *bp, X509 **x, pem_password_cb *cb, void *u);
X509_NAME *X509_get_subject_name(const X509 *x);
X509_NAME *X509_get_issuer_name(const X509 *x);

X509 *X509_new(void);
void X509_free(X509 *a);
]])

local C = ffi.C
local ffi_assert = base.ffi_assert
local tocdata = base.tocdata
local assert = assert
local _M = {}
local mt = {
  __index = _M,
  __new = ffi.new,
  __gc = function(self)
    C.X509_free(self.cdata)
  end
}

local X509 = ffi.metatype('struct { void *cdata; }', mt)

function _M.parse_pem_cert(str)
  local bio = BIO.new()

  assert(bio:write(str))

  local x509 = ffi_assert(C.PEM_read_bio_X509(bio.cdata, nil, nil, nil))

  return X509(x509)
end

function _M:subject_name()
  -- X509_get_subject_name() returns the subject name of certificate x.
  -- The returned value is an internal pointer which MUST NOT be freed.
  -- https://www.openssl.org/docs/man1.1.0/crypto/X509_get_subject_name.html
  return X509_NAME.new(C.X509_get_subject_name(tocdata(self)))
end

function _M:issuer_name()
  -- X509_get_issuer_name() and X509_set_issuer_name() are identical to X509_get_subject_name()
  -- and X509_set_subject_name() except the get and set the issuer name of x.
  -- https://www.openssl.org/docs/man1.1.0/crypto/X509_get_subject_name.html
  return X509_NAME.new(C.X509_get_issuer_name(tocdata(self)))
end

return _M
