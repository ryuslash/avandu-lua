local https = require 'ssl.https'
local json = require 'json'
local ltn12 = require 'ltn12'
local posix = require 'posix'

local ttrss_session_id = nil
local avandu = {}

avandu.ttrss_url = nil

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

function avandu.login (user, password)
   local response = call({op = "login",
                          user = user,
                          password = password})

   if response.status == 0 then
      return response.content.session_id
   end
end

local function get_credentials()
   local credfile = posix.getenv('HOME') .. '/.avandu.json'
   local iofile = io.open(credfile)
   local contents = iofile:read("*a")

   iofile:close()

   return json.decode(contents)
end

local function ensure_session_id ()
   if not ttrss_session_id then
      local creds = get_credentials()
      ttrss_session_id = avandu.login(creds.user, creds.password)
   end
end

function avandu.unread ()
   ensure_session_id()
   local response = call({op = "getUnread",
                          sid = ttrss_session_id})
   if response.status == 0 then
      return tonumber(response.content.unread)
   end
end

return avandu
