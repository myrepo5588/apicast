local _M = require('apicast.policy.oidc_default_configuration')

describe('oidc_default_configuration policy', function()
  describe('.new', function()
    it('works without configuration', function()
      assert(_M.new())
    end)

    it('accepts configuration', function()
        assert(_M.new({ }))
    end)
  end)
end)
