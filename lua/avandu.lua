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

--- A module to connect and communicate with Tiny Tiny RSS.
-- @module avandu
-- @author Tom Willemse <tom@ryuslash.org>
-- @license GPLv3
-- @copyright 2014 Tom Willemse
-- @release 0.1.0
local https = require 'ssl.https'
local json = require 'json'
local ltn12 = require 'ltn12'
local posix = require 'posix'
local logging = require 'logging'

local ttrss_session_id = nil
local avandu = {}

--- A dummy logger
local logger = logging.new(function (self, level, message)
      return true
end)

--- The url where the Tiny Tiny RSS API resides.
-- For example, this should be something like
-- `https://example.com/tt-rss/api/`.
avandu.ttrss_url = nil

--- A class to hold data about error conditions.
-- @field message Description of the error
-- @field url The URL a request was sent to
-- @field code The HTTP status code of the response
-- @field status Description of the HTTP status code of the response
avandu.Exception = {message = nil, url = nil, code = nil, status = nil}

--- Create a new exception from the given parameter.
-- Sets the metatable for the given parameter to the `Exception` class.
-- @tparam table params The values for the Exception
-- @treturn Exception `params`, but then with the metatable set to
--   `Exception`.
local function newex (params)
   setmetatable(params, avandu.Exception)
   return params
end

--- Send a request to Tiny Tiny RSS.
-- What the request entails depends on the contents of params.
-- @tparam table params Parameters for the request. This should at
--   least contain a value for `op` and for most requests also a
--   `sid`
-- @treturn[1] table The return value always contains a table of
--   sequence number (`seq`), status (`status`) and the contents of
--   the API's response as a table (`content`). The value of the
--   content depends on the API method called
-- @treturn[2] nil Indication that something went wrong
-- @treturn[2] Exception Information about what went wrong
local function call (params)
   local content = json.encode(params)
   local response = {}

   if not avandu.ttrss_url then
      return nil, newex({message = 'no URL set'})
   end

   logger:debug("Requesting with op `%s' from `%s'",
                params.op, avandu.ttrss_url)

   r, code, headers, status = https.request{
      url = avandu.ttrss_url,
      method = "POST",
      headers = {
         ["Content-Length"] = content:len()
      },
      protocol = 'tlsv1',
      sink = ltn12.sink.table(response),
      source = ltn12.source.string(content)
   }

   logger:debug("Request returned `%s' `%s' `%s' `%s'",
                r, code, logging.tostring(headers), status)

   if code == 200 then
      return json.decode(table.concat(response))
   elseif code == 404 then
      return nil, newex({message = 'URL not found',
                         url = avandu.ttrss_url,
                         code = code,
                         status = status})
   else
      return nil, newex({message = 'Unexpected HTTP status returned',
                         url = avandu.ttrss_url,
                         code = code,
                         status = status})
   end
end

--- Get a session ID from tt-rss by logging in.
-- If succesfull, this function will return the generated session ID.
-- @tparam string user The username
-- @tparam string password The password
-- @treturn[1] string|nil The generated session ID or nil
-- @treturn[2] nil Indication that something went wrong
-- @treturn[2] Exception Infomation about what went wrong
function avandu.login (user, password)
   local response, err = call({op = "login",
                               user = user,
                               password = password})

   if not response then
      return nil, err
   end

   if response.status == 0 then
      return response.content.session_id
   end

   return nil
end

--- Set the logger to use.
-- @param newlogger The logger to use
function avandu.set_logger (newlogger)
   logger = newlogger
end

--- Read the credentials necessary for loggin-in to Tiny Tiny RSS.
-- The information is read from the file `$HOME/.avandu.json` which
-- should contain a single json object with the fields `user` and
-- `password`.
-- @treturn table The username and password
-- @raise
-- - "The file ... could not be found" if the `.avandu.json` file
--   could not be accessed in the correct place.
-- - "The file ... has incorrect permissions" when the `.avandu.json`
--   file is not readable and writable *only* by the user.
local function get_credentials()
   local credfile = os.getenv('HOME') .. '/.avandu.json'
   local mode = posix.stat(credfile, 'mode')

   if not posix.access(credfile) then
      error('The file ' .. credfile .. ' could not be found', 0)
   elseif mode ~= 'rw-------' then
      error('The file ' .. credfile .. ' has incorrect permissions', 0)
   end

   local iofile = io.open(credfile)
   local contents = iofile:read("*a")

   iofile:close()

   return json.decode(contents)
end

--- Make sure we have a session ID.
-- If no session ID has been provided, log in to get one.
local function ensure_session_id ()
   if not ttrss_session_id then
      local creds = get_credentials()
      ttrss_session_id = avandu.login(creds.user, creds.password)
   end
end

--- Get the number of unread articles.
-- This function will try to log in if that hasn't happened yet.
-- @treturn[1] number The number of unread articles, or `-1` if there
--   was an error
-- @treturn[2] nil Indication that something went wrong
-- @treturn[2] Exception Information about what went wrong
function avandu.unread ()
   ensure_session_id()
   local response, err = call({op = "getUnread",
                               sid = ttrss_session_id})

   if not response then
      return nil, err
   end

   if response.status == 0 then
      return tonumber(response.content.unread)
   end

   return -1
end

return avandu
