--- An example of how to use avandu to write a CLI.
-- @module cli_example

-- Import avandu.
local avandu = require 'avandu'

-- Set the proper URL for the Tiny Tiny RSS API.
avandu.ttrss_url = "https://example.com/tt-rss/api/"

-- Get the number of unread articles and print the result.
local count, err = avandu.unread()

if count then
   print(count .. " unread article(s)")
else
   print("An error occurred: " .. err.message)
end
