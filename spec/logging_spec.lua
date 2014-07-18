-- Avandu Lua --- Lua client library for Tiny Tiny RSS
-- Copyright (C) 2014  Tom Willemse

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
local avandu = require 'avandu'
local logging = require 'logging'
local https = require 'ssl.https'

local function create_test_logger (output)
   return logging.new(function (self, level, message)
         table.insert(output, {level, message})
   end)
end

describe('Logging', function ()
   describe('With a URL', function ()
      it('should log both response and request', function ()
         logoutput = {}
         avandu.ttrss_url = 'anything'
         avandu.set_logger(create_test_logger(logoutput))
         https.request = function (params)
            return 1, 200, {['Content-Type'] = 'text/html'}, 'OK'
         end

         avandu.login('username', 'password')

         assert.are.same(
            {{"DEBUG", "Requesting with op `login' from `anything'"},
             {"DEBUG", "Request returned `1' `200' `{Content-Type = \"text/html\"}' `OK'"}},
            logoutput)
      end)
   end)

   describe('Without a URL', function ()
      it('should not log anything', function ()
         logoutput = {}
         avandu.ttrss_url = nil
         avandu.set_logger(create_test_logger(logoutput))

         avandu.login('username', 'password')

         assert.are.same({}, logoutput)
      end)
   end)
end)
