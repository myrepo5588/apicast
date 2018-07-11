local _M = require 'apicast.policy.3scale'

describe('APIcast policy', function()

  it('has a name', function()
    assert.truthy(_M._NAME)
  end)

  it('has a version', function()
    assert.truthy(_M._VERSION)
  end)
end)
