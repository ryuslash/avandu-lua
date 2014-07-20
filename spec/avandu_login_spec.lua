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

describe("Logging in to Tiny Tiny RSS", function()
  local url = 'anything'

  it("should return an error if no URL is set", function ()
    avandu.ttrss_url = nil
    local results, err = avandu.login('user', 'password')
    assert.falsy(results)
    assert.are.same(err, {message = 'no URL set'})
  end)

  it("should send the proper parameters to the request", function ()
    https.request = function (params)
       assert.are.same(params.url, url)
       assert.are.same(params.method, 'POST')
       assert.are.same(params.headers, {['Content-Length'] = 50})
       assert.are.same(params.protocol, 'tlsv1')
       assert.truthy(params.sink)
       assert.truthy(params.source)

       return 1, 200, {}, ''
    end

    avandu.ttrss_url = url
    avandu.login('user', 'password')
  end)

  it("should return a table of the JSON response", function ()
    https.request = function (params)
       params.sink(
          '{"status": 0, "content": {"session_id": 5}}'
       )
       return 1, 200, {}, ''
    end

    local results = avandu.login('user', 'password')
    assert.are.same(5, results)
  end)

  it("should return an exception upon a 404 HTTP error", function ()
    https.request = function (params)
       return 1, 404, {}, 'Not Found'
    end

    local results, err = avandu.login('login', 'password')
    assert.falsy(results)
    assert.are.same({message = 'URL not found', url = url, code = 404,
                     status = 'Not Found'}, err)
    assert.are.same(avandu.Exception, getmetatable(err))
  end)

  it("should return an exception upon any unexpected HTTP status", function()
    https.request = function (params)
       return 1, 500, {}, 'Internal Server Error'
    end

    local results, err = avandu.login('login', 'password')
    assert.falsy(results)
    assert.are.same({message = 'Unexpected HTTP status returned',
                     url = url, code = 500,
                     status = 'Internal Server Error'}, err)
    assert.are.same(avandu.Exception, getmetatable(err))
  end)

  it("should return nil for a non-0 status", function ()
    https.request = function (params)
       params.sink('{"status": 1}')
       return 1, 200, {}, ''
    end

    local results, err = avandu.login('user', 'password')
    assert.falsy(results)
    assert.falsy(err)
  end)
end)
