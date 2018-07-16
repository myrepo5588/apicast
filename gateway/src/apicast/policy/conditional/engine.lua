local lpeg = require('lpeg')

local tostring = tostring
local ipairs = ipairs
local loadstring = loadstring
local type = type
local sub = string.sub
local len = string.len
local pack = table.pack
local insert = table.insert
local concat = table.concat

local lpeg_P = lpeg.P
local lpeg_V = lpeg.V
local lpeg_C = lpeg.C
local lpeg_R = lpeg.R
local lpeg_S = lpeg.S

local _M = {}

local value_of = {
  request_method = function() return ngx.req.get_method() end,
  request_host = function() return ngx.var.host end,
  request_path = function() return ngx.var.uri end
}

local function value_of_attr(attr)
  return '"' .. value_of[attr]() .. '"'
end

local equivalent_lua_op = {
  ["&&"] = "and",
  ["||"] = "or",
  ["!="] = "~="
}

local function to_op(op)
  local equivalent = equivalent_lua_op[op]
  return equivalent or op
end

local function to_bool(s)
  if s == true or s == "true" then
    return true
  else
    return false
  end
end

local function evaluate(...)
  local expr = {}

  for _, arg in ipairs(pack(...)) do
    insert(expr, tostring(arg))
  end

  expr = concat(expr, ' ')

  local f
  if #pack(...) == 1 and sub(expr, 1, 1) == '"' then
    -- This is to keep " chars in strings so we know they're strings and not
    -- vars.
    -- When there's a single arg and it's a string we need to return something
    -- like "return '"GET"'" instead of "return 'GET'".
    f = loadstring("return " .. "'" .. expr .. "'")
  else
    f = loadstring("return " .. expr)
  end

  return f()
end

-- This method strips the " that were included to differentiate strings from
-- vars in evaluate().
local function parse_string(s)
  if type(s) == "string" and sub(s, 1, 1) == '"' then
    return sub(s, 2, len(s) - 1)
  else
    return s
  end
end

local parser = lpeg_P({
  "expr";

  -- Expressions are divided into 'expr', 'term', and 'fact'. This is to be
  -- able to give precedence to and over or. And to both of them over '==' and
  -- '!='.

  expr =
    (
      (
        lpeg_V("term") *
        lpeg_V("operator_or") *
        lpeg_V("expr")
      ) +
      lpeg_V("term")
    )
    / evaluate / parse_string,

  term =
    (
      (
        lpeg_V("fact") *
        lpeg_V("operator_and") *
        lpeg_V("term")
      ) +
      lpeg_V("fact")
    )
    / evaluate,

  fact =
    (
      lpeg_V("comparison") +
      (lpeg_V("spc") * lpeg_V("attr") * lpeg_V("spc")) +
      (lpeg_V("spc") * lpeg_V("bool") * lpeg_V("spc"))
    )
    / evaluate,

  comparison =
    lpeg_V("spc") *
    lpeg_V("attr") *
    lpeg_V("spc") *
    lpeg_V("op") *
    lpeg_V("spc") *
    lpeg_V("string") *
    lpeg_V("spc")
    / evaluate / to_bool,

  attr =
    lpeg_C(
      lpeg_P("request_method") +
      lpeg_P("request_host") +
      lpeg_P("request_path")
    )
    / value_of_attr,

  spc = lpeg_S(" \t\n")^0,

  op =
    lpeg_C(
      lpeg_P("==") +
      lpeg_P("~=") +
      lpeg_P("!=")
    )
    / to_op,

  operator_and =
    lpeg_C(
      lpeg_P("and") +
      lpeg_P("&&")
    )
    / to_op,

  operator_or =
    lpeg_C(
      lpeg_P("or") +
      lpeg_P("||")
    )
    / to_op,

  bool =
    lpeg_C(
      lpeg_P("true") +
      lpeg_P("false")
    )
    / to_bool,

  string =
    lpeg_C(
      (lpeg_P('"') + lpeg_P("'")) *
      (
        lpeg_R("AZ") +
        lpeg_R("az") +
        lpeg_R("09") +
        lpeg_S("/_")
      )^0 *
      (lpeg_P('"') + lpeg_P("'"))
    )
    / tostring
})

function _M.evaluate(expression)
  return parser:match(expression)
end

return _M
