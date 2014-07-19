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


describe('Getting unread articles from Tiny Tiny RSS', function ()
  local url = 'anything'

  helpers.define_credentials_test_for(avandu.unread)

  describe("with proper files", function ()
    before_each(helpers.proper_file_situation(url))

    helpers.define_nourl_test_for(avandu.unread)
    helpers.define_params_test_for(avandu.unread, url)

    it("should return a proper number of unread items", function ()
      https.request = function (params)
         params.sink('{"status": 0, "content": {"unread": 15}}')
         return '', 200, {}, ''
      end

      local result, err = avandu.unread()
      assert.are.same(15, result)
    end)

    helpers.define_404_test_for(avandu.unread, url)
    helpers.define_unexpected_test_for(avandu.unread, url)
    helpers.define_nonzero_test_for(avandu.unread, -1)
  end)
end)
