local https = require 'ssl.https'
local avandu = require 'avandu'

describe("Logging in to Tiny Tiny RSS", function()
  local url = 'anything'

  it("should return an error if no URL is set", function ()
    avandu.ttrss_url = nil
    local results, err = avandu.login()
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
    end

    avandu.ttrss_url = url
    avandu.login('user', 'password')
  end)

  it("should return a table of the JSON response", function ()
    https.request = function (params)
       params.sink(
          '{"status": 0, "content": {"session_id": 5}}'
       )
       return '', 200, '', ''
    end

    local results = avandu.login()
    assert.are.same(5, results)
  end)

  it("should return an exception upon a 404 HTTP error", function ()
    https.request = function (params)
       return '', 404, {}, 'Not Found'
    end

    local results, err = avandu.login()
    assert.falsy(results)
    assert.are.same({message = 'URL not found', url = url, code = 404,
                     status = 'Not Found'}, err)
    assert.are.same(avandu.Exception, getmetatable(err))
  end)

  it("should return an exception upon any unexpected HTTP status", function()
    https.request = function (params)
       return '', 500, {}, 'Internal Server Error'
    end

    local results, err = avandu.login()
    assert.falsy(results)
    assert.are.same({message = 'Unexpected HTTP status returned',
                     url = url, code = 500,
                     status = 'Internal Server Error'}, err)
    assert.are.same(avandu.Exception, getmetatable(err))
  end)

  it("should return nil for a non-0 status", function ()
    https.request = function (params)
       params.sink('{"status": 1}')
       return '', 200, {}, ''
    end

    local results, err = avandu.login()
    assert.falsy(results)
    assert.falsy(err)
  end)
end)
