--- A module to connect and communicate with Tiny Tiny RSS.
-- @module avandu
local https = require 'ssl.https'
local json = require 'json'
local ltn12 = require 'ltn12'
local posix = require 'posix'

local ttrss_session_id = nil
local avandu = {}

--- The url where the Tiny Tiny RSS API resides.
-- For example, this should be something like
-- `https://example.com/tt-rss/api/`.
avandu.ttrss_url = nil

--- Send a request to Tiny Tiny RSS.
-- What the request entails depends on the contents of params.
-- @tparam table params Parameters for the request. This should at
--   least contain a value for `op` and for most requests also a
--   `sid`.
-- @treturn table The return value always contains a table of sequence
--   number (`seq`), status (`status`) and the contents of the API's
--   response as a table (`content`). The value of the content depends
--   on the API method called.
local function call (params)
   local content = json.encode(params)
   local response = {}

   r, code, headers, other = https.request{
      url = avandu.ttrss_url,
      method = "POST",
      headers = {
         ["Content-Length"] = content:len()
      },
      protocol = 'tlsv1',
      sink = ltn12.sink.table(response),
      source = ltn12.source.string(content)
   }

   return json.decode(table.concat(response))
end

--- Get a session ID from tt-rss by logging in.
-- If succesfull, this function will return the generated session ID.
-- @tparam string user The username
-- @tparam string password The password
-- @treturn string|nil The generated session ID or nil
function avandu.login (user, password)
   local response = call({op = "login",
                          user = user,
                          password = password})

   if response.status == 0 then
      return response.content.session_id
   end

   return nil
end

--- Read the credentials necessary for loggin-in to Tiny Tiny RSS.
-- The information is read from the file `$HOME/.avandu.json` which
-- should contain a single json object with the fields `user` and
-- `password`.
-- @treturn table The username and password.
local function get_credentials()
   local credfile = posix.getenv('HOME') .. '/.avandu.json'
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
-- @treturn number The number of unread articles, or `-1` if there was an
--   error.
function avandu.unread ()
   ensure_session_id()
   local response = call({op = "getUnread",
                          sid = ttrss_session_id})
   if response.status == 0 then
      return tonumber(response.content.unread)
   end

   return -1
end

return avandu
