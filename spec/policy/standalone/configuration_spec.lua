local _M = require('apicast.policy.standalone.configuration')

describe('Standalone Configuration', function()
    describe('.new', function()
        it('accepts file url', function()
            assert(_M.new('file://tmp/conf.toml'))
        end)

        it('does not accept http', function()
            assert.returns_error('scheme not supported', _M.new('http://example.com'))
        end)

        it('does not accept https', function()
            assert.returns_error('scheme not supported', _M.new('https://example.com'))
        end)

        it('does not accept invalid URL', function()
            assert.returns_error('missing scheme', _M.new('invalid url'))
        end)
    end)
end)
