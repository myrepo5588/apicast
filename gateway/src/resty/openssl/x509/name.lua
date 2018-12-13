local base = require('resty.openssl.base')
local BIO = require('resty.openssl.bio')
local ffi = require('ffi')
local bit = require('bit')

ffi.cdef([[
int X509_NAME_print_ex(BIO *out, const X509_NAME *nm, int indent, unsigned long flags);
char * X509_NAME_oneline(const X509_NAME *a, char *buf, int size);
int X509_NAME_print(BIO *bp, const X509_NAME *name, int obase);
]])

local XN_FLAG_SEP_MASK = bit.lshift(0xf, 16)

local XN_FLAG_COMPAT = 0
local XN_FLAG_SEP_COMMA_PLUS = bit.lshift(1, 16)
local XN_FLAG_SEP_CPLUS_SPC = bit.lshift(2, 16)
local XN_FLAG_SEP_SPLUS_SPC = bit.lshift(3, 16)
local XN_FLAG_SEP_MULTILINE = bit.lshift(4, 16)

local XN_FLAG_DN_REV = bit.lshift(1, 20)

local XN_FLAG_FN_MASK = bit.lshift(0x3, 21)

local XN_FLAG_FN_SN = 0
local XN_FLAG_FN_LN = bit.lshift(1, 21)
local XN_FLAG_FN_OID = bit.lshift(2, 21)
local XN_FLAG_FN_NONE = bit.lshift(3, 21)

local XN_FLAG_SPC_EQ = bit.lshift(1, 23)

local XN_FLAG_DUMP_UNKNOWN_FIELDS = bit.lshift(1, 24)

local XN_FLAG_FN_ALIGN = bit.lshift(1, 25)

local ASN1_STRFLGS_ESC_2253 = 1
local ASN1_STRFLGS_ESC_CTRL = 2
local ASN1_STRFLGS_ESC_MSB = 4

local ASN1_STRFLGS_ESC_QUOTE = 8

local CHARTYPE_PRINTABLESTRING = 0x10

local CHARTYPE_FIRST_ESC_2253 = 0x20

local CHARTYPE_LAST_ESC_2253 = 0x40

local ASN1_STRFLGS_UTF8_CONVERT = 0x10

local ASN1_STRFLGS_IGNORE_TYPE = 0x20

local ASN1_STRFLGS_SHOW_TYPE = 0x40

local ASN1_STRFLGS_DUMP_ALL = 0x80
local ASN1_STRFLGS_DUMP_UNKNOWN = 0x100

local ASN1_STRFLGS_DUMP_DER = 0x200

local SN1_STRFLGS_ESC_2254 = 0x400

local ASN1_STRFLGS_RFC2253 = bit.bor(ASN1_STRFLGS_ESC_2253,
    ASN1_STRFLGS_ESC_CTRL,
    ASN1_STRFLGS_ESC_MSB,
    ASN1_STRFLGS_UTF8_CONVERT,
    ASN1_STRFLGS_DUMP_UNKNOWN,
    ASN1_STRFLGS_DUMP_DER)

local XN_FLAG_RFC2253 = bit.bor(ASN1_STRFLGS_RFC2253,
    XN_FLAG_SEP_COMMA_PLUS,
    XN_FLAG_DN_REV,
    XN_FLAG_FN_SN,
    XN_FLAG_DUMP_UNKNOWN_FIELDS)

local XN_FLAG_ONELINE = bit.bor(ASN1_STRFLGS_RFC2253,
    ASN1_STRFLGS_ESC_QUOTE,
    XN_FLAG_SEP_CPLUS_SPC,
    XN_FLAG_SPC_EQ,
    XN_FLAG_FN_SN)

local XN_FLAG_MULTILINE = bit.bor(ASN1_STRFLGS_ESC_CTRL,
    ASN1_STRFLGS_ESC_MSB,
    XN_FLAG_SEP_MULTILINE,
    XN_FLAG_SPC_EQ,
    XN_FLAG_FN_LN,
    XN_FLAG_FN_ALIGN)

local C = ffi.C
local tocdata = base.tocdata
local assert = assert
local _M = {}
local mt = {
  __index = _M,
  __new = ffi.new,
  __tostring = function(self)
    local bio = BIO.new()
    C.X509_NAME_print_ex(tocdata(bio), tocdata(self), 0, XN_FLAG_ONELINE)

    return bio:read()
  end
}

local X509_NAME = ffi.metatype('struct { X509_NAME *cdata; }', mt)

function _M.new(name)
  return X509_NAME(assert(name))
end

return _M
