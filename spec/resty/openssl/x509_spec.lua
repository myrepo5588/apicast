local _M = require('resty.openssl.x509')
local ssl = require('ngx.ssl')
local ffi = require('ffi')

ffi.cdef([[
typedef struct stack_st OPENSSL_STACK;

int OPENSSL_sk_num(const OPENSSL_STACK *);
void *OPENSSL_sk_value(const OPENSSL_STACK *, int);
]])

local function PEM_to_X509(pem)
  local chain = ssl.parse_pem_cert(pem)
  return ffi.C.OPENSSL_sk_value(chain, 0), chain
end

local CA = PEM_to_X509([[
-----BEGIN CERTIFICATE-----
MIICvDCCAaQCCQCep4rpEMmCcDANBgkqhkiG9w0BAQsFADAgMR4wHAYDVQQDDBVD
ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTgxMjA2MTcwNTQ3WhcNMjgxMjAzMTcw
NTQ3WjAgMR4wHAYDVQQDDBVDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggEiMA0GCSqG
SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqIfkTccBdVmBqoewL2gBnkDOwk9cKBcLn
uIPge4GfO1Vm4AhDFyZOH9gUmjRH+5Dfu/G+dq7U1jOxTQnvs5U/4857PCTc/rdf
TT/HcG8k6GhBMq6/+gwtT/nOxcFmDkyAOBR2DpvwOd1soOU7lokHkDYTv+kPKrRP
Gc6x7cl3NrsAK154u1xNAGDZiEeThBmi2EanTEZOx4dqkc5pD89P5A/vwjV5LJ+v
jtL+P1FOgK57B3fVFqTL1TNOQdH9BWRZ7z3ZPfSn1PokKA4fazTOZ0iXeQVSIqju
msRk91o+CFXNPJS8NRMsp6Nk6iClyXtaxBWzAcnAxSf9u/UZ6murAgMBAAEwDQYJ
KoZIhvcNAQELBQADggEBAIZo62o53KVLWnDCBxFHwhKVgPa95o1E3RJWuRTI8kdX
L8tehLHorqOCZ1zNIDv8l2QErVUvcxwL/lpuJWZLUvhHPYUg6FDKB+vapVd1yRgR
o4fWkEQkMiKZ4bsSmM00udS5pYGiMHc3vjBcmEPzACIfcv+K29F58Lb3v2ccIXh3
5pQvDYhqaeivRK6JIDY/+1UnaQt65DeNDAfGeAdar6DbFW+gju9avYGINRJP+BGC
Wce2mRmiNUqt37UO1+NXSLa9+4By0j5I1dMqCRFjwQBUaDgrhQf1xpVbEQ30myyy
Ci818xLwDp7CENLKIBNtg88u9Z+ha81pscKiG9WXCLI=
-----END CERTIFICATE-----
]])

local client = PEM_to_X509([[
-----BEGIN CERTIFICATE-----
MIICvDCCAaQCCQDyra7VGipAyzANBgkqhkiG9w0BAQsFADAgMR4wHAYDVQQDDBVD
ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTgxMjA2MTcwOTA1WhcNMjgxMjAzMTcw
OTA1WjAgMQ8wDQYDVQQKDAZDbGllbnQxDTALBgNVBAMMBGN1cmwwggEiMA0GCSqG
SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDt9H6xhm0pGqARRGMaUrSbZvetrN1mo+O4
KuqPRr8I/YhvOEPlc/8VMxF3nyETGjQ+khO9FJGDoDD2S3yGzt1FFiNI6AOPkmux
DZMUQ2alnS7fG0zBUlxRx9otoMx/vH4gnKTfmHofuwPwkLPSWoHf0ZmPLXbm19ds
aKvllOX8vjEjtNprtUzveeDOnuov2GXqo/w+FOnDxYhys1Oidx3LOje5izV7EX4+
+HH+7EwRV7m4+s/G97z5soo1XIZHHQKKC0DONWTOdeLkqLlAqU0nuuRkFzmbrD4u
2haxqcuyficBgbFWZznLDxJ1fMJzen7YbYea1GycTKe6Wt4xviDDAgMBAAEwDQYJ
KoZIhvcNAQELBQADggEBADY5udciqAIAFtJWVQ+AT+5RAWClGlEfi7wAfsGWUIpi
1mQjkGSqbZ4DSEECsRNiokjSyA5Phi9REg8tDCVaovMANncptUX6PJzCkpkdD5Wo
cMWzF8dZpphyZH+RwGM7aTGmdz/mnxKtVoTt++wLNv2jardRKoFvyu+FBzpTbWBe
2EYaIlGHRrIMoU9ZK3D2rGHK3GsakZT3e76/P5KuyIp1+K7IEWmD4Fk3GM6uM+Rc
Q7zGkdX+LBr85p07DHTcDxAwIT6xXh2J1fhiyart5sHkMg6YZ5JpjitIOEypnyiq
KjTINz0a+0rohUDR6BWkdU5R8Bpbw1Pg7Owx9B51KQM=
-----END CERTIFICATE-----
]])


describe('OpenSSL X509', function ()

  describe('X509_STORE', function ()
    it('creates X509_STORE', function ()
      assert(_M.STORE_new())
    end)

    it('adds certificate to the store', function()
      assert(_M.STORE_new():add_cert(CA))
    end)
  end)

  describe('X509_STORE_CTX', function ()
    it('creates X509_STORE_CTX', function ()
      assert(_M.STORE_CTX_new())
    end)

    it('adds certificate to the store', function()
      local store = _M.STORE_new()

      store:add_cert(CA)

      local ctx = _M.STORE_CTX_new(store, client)

      assert(ctx:verify())
      -- assert(ctx:verify()) -- this fails, we should design nice API impossible to misuse (not like OpenSSL)
    end)
  end)

end)
