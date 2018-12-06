local _M = require('apicast.policy.tls_validation')

describe('tls_validation policy', function()
  describe('.new', function()
    it('works without configuration', function()
      assert(_M.new())
    end)

    it('accepts configuration', function()
        assert(_M.new({ }))
    end)
  end)
end)
