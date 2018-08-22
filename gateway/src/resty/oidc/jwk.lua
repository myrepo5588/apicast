local b64 = require('ngx.base64')
local ffi = require('ffi')
local tab_new = require('resty.core.base').new_tab

ffi.cdef [[
typedef struct bio_st BIO;
typedef struct bio_method_st BIO_METHOD;
BIO_METHOD *BIO_s_mem(void);
BIO * BIO_new(BIO_METHOD *type);
void BIO_vfree(BIO *a);
int BIO_read(BIO *b, void *data, int len);

size_t BIO_ctrl_pending(BIO *b);

typedef struct bignum_st BIGNUM;
typedef void FILE;

BIGNUM *BN_bin2bn(const unsigned char *s, int len, BIGNUM *ret);
void BN_clear_free(BIGNUM *a);

int RSA_set0_key(RSA *r, BIGNUM *n, BIGNUM *e, BIGNUM *d);
RSA * RSA_new(void);

void RSA_free(RSA *rsa);

int RSA_print_fp(FILE *fp, RSA *x, int offset);

int PEM_write_RSA_PUBKEY(FILE *fp, RSA *x);
int PEM_write_bio_RSA_PUBKEY(BIO *bp, RSA *x);
]]

local C = ffi.C
local ffi_gc = ffi.gc

local ipairs = ipairs

local _M = { }

_M.jwk_to_pem = { }

local function b64toBN(str)
    local val, err = b64.decode_base64url(str)
    if not val then return nil, err end

    local bn = C.BN_bin2bn(val, #val, nil) -- TODO: handle failure

    ffi_gc(bn, C.BN_clear_free)

    return bn
end

local function read_BIO(bio)
    local len = C.BIO_ctrl_pending(bio)
    local buf = ffi.new("char[?]", len)
    C.BIO_read(bio, buf, len) -- TODO: handle failure
    return ffi.string(buf, len)
end

local function new_BIO()
    local bio = C.BIO_new(C.BIO_s_mem())
    ffi_gc(bio, C.BIO_vfree)

    return bio
end

local function RSA_to_PEM(rsa)
    local bio = new_BIO()

    C.PEM_write_bio_RSA_PUBKEY(bio, rsa) -- TODO: handle failure

    return read_BIO(bio)
end

function _M.jwk_to_pem.RSA(jwk)
    local n, e, err

    --- https://github.com/sfackler/rust-openssl/blob/2df87cfd5974da887b5cb84c81e249f485bed9f7/openssl/src/rsa.rs#L420-L437
    local rsa = C.RSA_new()
    ffi_gc(rsa, C.RSA_free)

    -- parameter n: Base64 URL encoded string representing the modulus of the RSA Key.
    n, err = b64toBN(jwk.n)
    if err then return nil, err end

    -- parameter e: Base64 URL encoded string representing the public exponent of the RSA Key.
    e, err = b64toBN(jwk.e)
    if err then return nil, err end

    C.RSA_set0_key(rsa, n, e, nil); -- TODO: handle failure

    -- jwk.rsa = rsa
    jwk.pem = RSA_to_PEM(rsa)

    return jwk
end

function _M.convert_keys(res)
    if not res then return end
    local keys = tab_new(0, #res.keys)

    for i,jwk in ipairs(res.keys) do
        keys[jwk.kid] = _M.convert_jwk_to_pem(jwk)
    end

    return keys
end

function _M.convert_jwk_to_pem(jwk)
    local fun = _M.jwk_to_pem[jwk.kty]

    if not fun then
        return nil, 'unsupported kty'
    end

    return fun(jwk)
end

return _M
