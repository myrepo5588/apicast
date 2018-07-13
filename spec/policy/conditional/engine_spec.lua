local Engine = require('apicast.policy.conditional.engine')

describe('Engine', function()
  describe('.evaluate', function()
    it('evaluates "request_method"', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)

      assert.equals('GET', Engine.evaluate("request_method"))
    end)

    it('evaluates "request_host"', function()
      ngx.var = { host = 'localhost' }

      assert.equals('localhost', Engine.evaluate("request_host"))
    end)

    it('evaluates "request_path"', function()
      ngx.var = { uri = '/some_path' }

      assert.equals('/some_path', Engine.evaluate("request_path"))
    end)

    it('evaluates true', function()
      assert.is_true(Engine.evaluate("true"))
    end)

    it('evaluates false', function()
      assert.is_false(Engine.evaluate("false"))
    end)

    it('evaluates "=="', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)

      assert.is_true(Engine.evaluate('request_method == "GET"'))
      assert.is_false(Engine.evaluate('request_method == "POST"'))
    end)

    it('evaluates "~="', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)

      assert.is_true(Engine.evaluate('request_method ~= "POST"'))
      assert.is_false(Engine.evaluate('request_method ~= "GET"'))
    end)

    it('evaluates "!=', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)

      assert.is_true(Engine.evaluate('request_method != "POST"'))
      assert.is_false(Engine.evaluate('request_method != "GET"'))
    end)

    it('evaluates "and"', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path' }

      assert.is_false(Engine.evaluate(
        'request_method == "POST" and request_path == "/invalid"'))
      assert.is_false(Engine.evaluate(
        'request_method == "POST" and request_path == "/some_path"'))
      assert.is_false(Engine.evaluate(
        'request_method == "GET" and request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" and request_path == "/some_path"'))
    end)

    it('evaluates "&&"', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path' }

      assert.is_false(Engine.evaluate(
        'request_method == "POST" && request_path == "/invalid"'))
      assert.is_false(Engine.evaluate(
        'request_method == "POST" && request_path == "/some_path"'))
      assert.is_false(Engine.evaluate(
        'request_method == "GET" && request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" && request_path == "/some_path"'))
    end)

    it('evaluates "or"', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path' }

      assert.is_false(Engine.evaluate(
        'request_method == "POST" or request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "POST" or request_path == "/some_path"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" or request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" or request_path == "/some_path"'))
    end)

    it('evaluates "||"', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path' }

      assert.is_false(Engine.evaluate(
        'request_method == "POST" || request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "POST" || request_path == "/some_path"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" || request_path == "/invalid"'))
      assert.is_true(Engine.evaluate(
        'request_method == "GET" || request_path == "/some_path"'))
    end)

    it('evaluates several chained ands', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path', host = 'localhost' }

      assert.is_true(Engine.evaluate(
        'request_method == "GET" and request_path == "/some_path" and request_host == "localhost"'))
      assert.is_false(Engine.evaluate(
        'request_method == "GET" and request_path == "/some_path" and request_host == "invalid"'))
    end)

    it('evaluates several chained ors', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path', host = 'localhost' }

      assert.is_true(Engine.evaluate(
        'request_method == "invalid" or request_path == "/invalid" or request_host == "localhost"'))
      assert.is_false(Engine.evaluate(
        'request_method == "invalid" or request_path == "/invalid" or request_host == "invalid"'))
    end)

    it('evaluates several chained ands and ors giving precedence to and', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)
      ngx.var = { uri = '/some_path', host = 'localhost' }

      -- true or true and false = true
      assert.is_true(Engine.evaluate(
        'request_method == "GET" or request_path == "/invalid" and request_host == "invalid"'))
    end)

    it('evaluates strings between \' and between ""', function()
      stub(ngx.req, 'get_method', function () return 'GET' end)

      assert.is_true(Engine.evaluate('request_method == "GET"'))
      assert.is_true(Engine.evaluate("request_method == 'GET'"))
    end)

    it('returns nil for expressions that cannot be evaluated', function()
      assert.is_nil(Engine.evaluate('some_attr <> "GET"'))
    end)
  end)
end)
