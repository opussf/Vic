#!/usr/bin/env lua

addonData = { ["version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "Vic"

function test.before()
end
function test.after()
end
function test.testNOOP()
end

test.run()
