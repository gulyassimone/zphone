-- Adjust package path so tests can require project files
package.path = package.path ..
';./?.lua;./?/init.lua;./client/?.lua;./client/?/?.lua;./client/tests/?.lua;./client/tests/?/?.lua'

require('client.tests.apps_spec')
require('client.tests.main_spec')

local runner = require('client.tests.runner')
runner.run()
