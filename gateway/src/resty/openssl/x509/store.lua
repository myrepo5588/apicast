local base = require('resty.openssl.base')
local ffi = require('ffi')

ffi.cdef([[
// https://www.openssl.org/docs/man1.1.0/crypto/X509_STORE_new.html
X509_STORE *X509_STORE_new(void);
void X509_STORE_free(X509_STORE *v);
int X509_STORE_lock(X509_STORE *v);
int X509_STORE_unlock(X509_STORE *v);
int X509_STORE_up_ref(X509_STORE *v);

// https://www.openssl.org/docs/man1.1.1/man3/X509_STORE_add_cert.html
int X509_STORE_add_cert(X509_STORE *store, X509 *x);
int X509_STORE_add_crl(X509_STORE *ctx, X509_CRL *x);
int X509_STORE_set_depth(X509_STORE *store, int depth);
int X509_STORE_set_flags(X509_STORE *ctx, unsigned long flags);
int X509_STORE_set_purpose(X509_STORE *ctx, int purpose);
int X509_STORE_set_trust(X509_STORE *ctx, int trust);

// https://www.openssl.org/docs/man1.1.1/man3/X509_VERIFY_PARAM_set_depth.html
]])

local C = ffi.C
local ffi_assert = base.ffi_assert

local _M = {}
local mt = {
  __index = _M,
  __new = function(ct)
    local store = ffi_assert(C.X509_STORE_new())

    ffi.gc(store, C.X509_STORE_free)

    return ffi.new(ct, store)
  end
}

-- no changes to the metamethods possible from this point
local X509_STORE = ffi.metatype('struct { void *x509_store; }', mt)

function _M:add_cert(x509)
  return ffi_assert(C.X509_STORE_add_cert(self.x509_store, x509))
end

function _M.new()
  return X509_STORE()
end

return _M
