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
local https = require 'ssl.https'
local avandu = require 'avandu'
local helpers = require 'helpers'

describe('Getting the API level from Tiny Tiny RSS', function ()
   local url = 'anything'

   it('should raise an error if the credentials file doesn\'t exist',
      helpers.define_credentials_existence_test_for(avandu.get_api_level))
   it('should raise an error if the credentials file has the wrong permissions',
      helpers.define_credentials_permission_test_for(avandu.get_api_level))

   describe("with proper files", function ()
      before_each(helpers.proper_file_situation(url))

      it('should return an error without a URL',
         helpers.define_nourl_test_for(avandu.get_api_level))
      it('should send the proper parameters to the request',
         helpers.define_params_test_for(avandu.get_api_level, url))

      it("should return a proper API level", function ()
         https.request = function (params)
            params.sink('{"status": 0, "content": {"level": 8}}')
            return 1, 200, {}, ''
         end

         local result, err = avandu.get_api_level()
         assert.are.same(8, result)
      end)

      it('should return an exception upon a 404 HTTP error',
         helpers.define_404_test_for(avandu.get_api_level, url))
      it('should return an exception upon any unexpected HTTP status',
         helpers.define_unexpected_test_for(avandu.get_api_level, url))
      it('should return 0 for a non-0 status',
         helpers.define_nonzero_test_for(avandu.get_api_level, 0))
   end)
end)
