local ffi = require "ffi"

ffi.cdef([[
typedef struct stack_st OPENSSL_STACK;

int OPENSSL_sk_num(const OPENSSL_STACK *);
void *OPENSSL_sk_value(const OPENSSL_STACK *, int);

X509_STORE *X509_STORE_new(void);
void X509_STORE_free(X509_STORE *v);
int X509_STORE_lock(X509_STORE *v);
int X509_STORE_unlock(X509_STORE *v);
int X509_STORE_up_ref(X509_STORE *v);

X509_STORE_CTX *X509_STORE_CTX_new(void);
void X509_STORE_CTX_free(X509_STORE_CTX *ctx);

int X509_STORE_CTX_init(X509_STORE_CTX *ctx, X509_STORE *store,
                        X509 *x509, const OPENSSL_STACK *chain);

int X509_verify_cert(X509_STORE_CTX *ctx);
int   X509_STORE_CTX_get_error(X509_STORE_CTX *ctx);

const char *X509_verify_cert_error_string(long n);

]])

local C = ffi.C
local setmetatable = setmetatable

local _M = {}

local X509_STORE = { }
local X509_STORE_CTX = { }
local STORE_mt = { __index = X509_STORE }
local STORE_CTX_mt = { __index = X509_STORE_CTX }

function X509_STORE:add_cert(x509)
  return assert(C.X509_STORE_add_cert(self.X509_STORE, x509))
end

function X509_STORE_CTX:verify()
  local ctx = self.X509_STORE_CTX
  local ret = C.X509_verify_cert(ctx)

  if ret == 1 then
    return true
  else
    return false, ffi.string(C.X509_verify_cert_error_string(C.X509_STORE_CTX_get_error(ctx)))
  end
end

function _M.STORE_new()
  local p = assert(C.X509_STORE_new())
  ffi.gc(p, C.X509_STORE_free)
  return setmetatable({ X509_STORE = p }, STORE_mt)
end

function _M.STORE_CTX_new(store, cert, chain)
  local p = assert(C.X509_STORE_CTX_new())

  assert(C.X509_STORE_CTX_init(p, store and store.X509_STORE, cert, chain) == 1)

  return setmetatable({ X509_STORE_CTX = p }, STORE_CTX_mt)
end

return _M
