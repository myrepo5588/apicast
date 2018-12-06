local _M = require('resty.openssl.x509')
local ssl = require('ngx.ssl')
local pem = [[-----BEGIN CERTIFICATE-----
MIIBRzCB7gIJAPHi8uNGM8wDMAoGCCqGSM49BAMCMCwxFjAUBgNVBAoMDVRlc3Q6
OkFQSWNhc3QxEjAQBgNVBAMMCWxvY2FsaG9zdDAeFw0xODA2MDUwOTQ0MjRaFw0y
ODA2MDIwOTQ0MjRaMCwxFjAUBgNVBAoMDVRlc3Q6OkFQSWNhc3QxEjAQBgNVBAMM
CWxvY2FsaG9zdDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABI3IZUvpJsaQbiLy
/yfthJDd/+BIaKzAbgMAimth4ePOi3a/YICwsHyq6sBxbgvMeTwxNJIHpe3td4tB
VZ5Wr10wCgYIKoZIzj0EAwIDSAAwRQIhAPRkfbxowt0H7p5xZYpwoMKanUXz9eKQ
0sGkOw+TqqGXAiAMKJRqtjnCF2LIjGygHG6BlgjM4NgIMDHteZPEr4qEmw==
-----END CERTIFICATE-----]]

local ffi = require('ffi')

ffi.cdef([[
typedef struct stack_st OPENSSL_STACK;

int OPENSSL_sk_num(const OPENSSL_STACK *);
void *OPENSSL_sk_value(const OPENSSL_STACK *, int);
]])

local chain = ssl.parse_pem_cert(pem)
local crt = ffi.C.OPENSSL_sk_value(chain, 0)

describe('OpenSSL X509', function ()

  describe('X509_STORE', function ()
    it('creates X509_STORE', function ()
      assert(_M.STORE_new())
    end)

    it('adds certificate to the store', function()
      assert(_M.STORE_new():add_cert(crt))
    end)
  end)

  describe('X509_STORE_CTX', function ()
    it('creates X509_STORE_CTX', function ()
      assert(_M.STORE_CTX_new())
    end)

    it('adds certificate to the store', function()
      local store = _M.STORE_new()

      store:add_cert(crt)

      local ctx = _M.STORE_CTX_new(store, crt)

      assert(ctx:verify())
    end)
  end)

end)
