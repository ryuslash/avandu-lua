local https = require 'ssl.https'
local posix = require 'posix'
local avandu = require 'avandu'

local function yes () return true end
local function no () return false end
local function ureadable () return 'rw-------' end
local function goreadable () return 'rw-rw-rw-' end

local function fakefile()
   return {read = function ()
              return '{"user": "user", "password": "password"}'
           end,
           close = function () end}
end

describe('Getting unread articles from Tiny Tiny RSS', function ()
  local url = 'anything'

  it('should raise an error if the credentials file doesn\'t exist', function ()
    posix.access = no

    credfile = os.getenv('HOME') .. '/.avandu.json'
    assert.has_error(avandu.unread,
                     'The file ' .. credfile .. ' could not be found')
  end)

  it('should raise an error if the credentials file has the wrong permissions', function ()
    posix.access = yes
    posix.stat = goreadable

    credfile = os.getenv('HOME') .. '/.avandu.json'
    assert.has_error(avandu.unread,
                     'The file ' .. credfile .. ' has incorrect permissions')
  end)

  describe("with proper files", function ()
    before_each(function ()
      posix.access = yes
      posix.stat = ureadable
      io.open = fakefile
      avandu.ttrss_url = url
    end)

    it('should return an error without a URL', function ()
      avandu.ttrss_url = nil
      local result, err = avandu.unread()

      assert.falsy(result)
      assert.are.same({message = 'no URL set'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
    end)

    it("should send the proper parameters to the request", function ()
      https.request = function (params)
         assert.are.same(params.url, url)
         assert.are.same(params.method, 'POST')
         assert.are.same(
            {['Content-Length'] = params.source():len()}, params.headers)
         assert.are.same(params.protocol, 'tlsv1')
         assert.truthy(params.sink)
         assert.truthy(params.source)
      end

      avandu.unread()
    end)

    it("should return a proper number of unread items", function ()
      https.request = function (params)
         params.sink('{"status": 0, "content": {"unread": 15}}')
         return '', 200, {}, ''
      end

      local result, err = avandu.unread()
      assert.are.same(15, result)
    end)

    it("should return an exception upon a 404 HTTP error", function ()
      https.request = function (params)
         return '', 404, {}, 'Not Found'
      end

      local results, err = avandu.unread()
      assert.falsy(results)
      assert.are.same({message = 'URL not found', url = url, code = 404,
                       status = 'Not Found'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
    end)

    it("should return an exception upon any unexpected HTTP status", function ()
      https.request = function (params)
         return '', 500, {}, 'Internal Server Error'
      end

      local results, err = avandu.unread()
      assert.falsy(results)
      assert.are.same({message = 'Unexpected HTTP status returned',
                       url = url, code = 500,
                       status = 'Internal Server Error'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
    end)

    it("should return -1 for a non-0 status", function ()
      https.request = function (params)
         params.sink('{"status": 1}')
         return '', 200, {}, ''
      end

      local results, err = avandu.unread()
      assert.are.same(-1, results)
      assert.falsy(err)
    end)
  end)
end)
