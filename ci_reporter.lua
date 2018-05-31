local TAP = require('busted.outputHandlers.TAP')
local JUnit = require('busted.outputHandlers.junit')


return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()

  local tap = TAP(setmetatable({ }, { __index = options }))
  local junit = JUnit(setmetatable({
    arguments = { 'tmp/junit/busted.xml' },
  }, { __index = options }))

  function handler:subscribe(options)
    tap:subscribe(options)
    junit:subscribe(options)
  end

  return handler
end
