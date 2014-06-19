--- An example of how to use avandu with awesome.
-- @module awesome_example

-- ... Awesome imports

-- Import avandu.
local avandu = require 'avandu'

-- ...

-- Set the proper URL for the Tiny Tiny RSS API.
avandu.ttrss_url = "https://example.com/tt-rss/api/"

-- Create a widget to show the number of unread articles.
myrsslist = wibox.widget.textbox()
myrsslist:set_text(string.format(" rss: %d", avandu.unread()))

-- Create a timer to update the widget once every 60 seconds.
myrsslisttimer = timer({ timeout = 60 })
myrsslisttimer:connect_signal(
   "timeout",
   function ()
      myrsslist:set_text(string.format(" rss: %d", avandu.unread()))
   end
)
myrsslisttimer:start()

-- ...

for s = 1, screen.count() do
   -- ...

   if s == 1 then
      -- Add the created widget to the wibox.
      right_layout:add(myrsslist)
      -- ...
   end

   -- ...
end

-- ...
