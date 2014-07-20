local avandu = require 'avandu'
local https = require 'ssl.https'
local posix = require 'posix'

local helpers = {}

function helpers.yes () return true end
function helpers.no () return false end
function helpers.goreadable () return 'rw-rw-rw-' end
function helpers.ureadable () return 'rw-------' end

function helpers.fakefile()
   return {read = function ()
              return '{"user": "user", "password": "password"}'
           end,
           close = function () end}
end

function helpers.proper_file_situation (url)
   return function ()
      posix.access = helpers.yes
      posix.stat = helpers.ureadable
      io.open = helpers.fakefile
      avandu.ttrss_url = url
   end
end

function helpers.define_credentials_existence_test_for (testfunc)
   return function ()
      posix.access = helpers.no

      credfile = os.getenv('HOME') .. '/.avandu.json'
      assert.has_error(testfunc,
                       'The file ' .. credfile .. ' could not be found')
   end
end

function helpers.define_credentials_permission_test_for (testfunc)
   return function ()
      posix.access = helpers.yes
      posix.stat = helpers.goreadable

      credfile = os.getenv('HOME') .. '/.avandu.json'
      assert.has_error(testfunc,
                       'The file ' .. credfile .. ' has incorrect permissions')
   end
end

function helpers.define_nourl_test_for (testfunc)
   return function ()
      avandu.ttrss_url = nil
      local result, err = testfunc()

      assert.falsy(result)
      assert.are.same({message = 'no URL set'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
   end
end

function helpers.define_params_test_for (testfunc, url)
   return function ()
      https.request = function (params)
         assert.are.same(params.url, url)
         assert.are.same(params.method, 'POST')
         assert.are.same(
            {['Content-Length'] = params.source():len()}, params.headers)
         assert.are.same(params.protocol, 'tlsv1')
         assert.truthy(params.sink)
         assert.truthy(params.source)

         return 1, 200, {}, ''
      end

      testfunc()
   end
end

function helpers.define_404_test_for (testfunc, url)
   return function ()
      https.request = function (params)
         return '', 404, {}, 'Not Found'
      end

      local results, err = testfunc()
      assert.falsy(results)
      assert.are.same({message = 'URL not found', url = url, code = 404,
                       status = 'Not Found'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
   end
end

function helpers.define_unexpected_test_for (testfunc, url)
   return function ()
      https.request = function (params)
         return '', 500, {}, 'Internal Server Error'
      end

      local results, err = testfunc()
      assert.falsy(results)
      assert.are.same({message = 'Unexpected HTTP status returned',
                       url = url, code = 500,
                       status = 'Internal Server Error'}, err)
      assert.are.same(avandu.Exception, getmetatable(err))
   end
end

function helpers.define_nonzero_test_for (testfunc, expected)
   return function ()
      https.request = function (params)
         params.sink('{"status": 1}')
         return '', 200, {}, ''
      end

      local results, err = testfunc()
      assert.are.same(expected, results)
      assert.falsy(err)
   end
end

return helpers
