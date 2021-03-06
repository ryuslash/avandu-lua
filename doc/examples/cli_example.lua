--- An example of how to use avandu to write a CLI.
-- @module cli_example

-- Import avandu.
local avandu = require 'avandu'

-- Set the proper URL for the Tiny Tiny RSS API.
avandu.ttrss_url = "https://ryuslash.org/tt-rss/api/"

-- local consolelog = require 'logging.console'
-- logger = consolelog()
-- avandu.set_logger(logger)

-- Get the API level of the installed Tiny Tiny RSS instance.
local status, level, err = pcall(avandu.get_api_level)

if status then
   if level then
      print("Your instance runs API level " .. level)
   else
      print("An error occurred: " .. err.message)
   end
else
   print("An exception occurred: " .. level)
end

-- Get the number of unread articles and print the result.
local status, count, err = pcall(avandu.unread)

if status then
   if count then
      print(count .. " unread article(s)")
   else
      print("An error occurred: " .. err.message)
   end
else
   print("An exception occurred: " .. count)
end
