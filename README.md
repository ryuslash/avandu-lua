# Avandu Lua

A Lua-based Tiny Tiny RSS API implementation, mostly meant for use in
the [awesome window manager](http://awesome.naquadah.org).

## Installation

Installation should go as follows.

### Grab it from github

There are currently no real releases, so using this module you will
need to get it from the git master branch.

        git clone git://github.com/ryuslash/avandu-lua.git

### (If necessary) add it to `package.path`

Put it somewhere you can find it, perhaps in the general vicinity of
your awesome configuration.

Add the path to avandu-lua to `package.path`, if necessary:

        package.path = '/path/to/avandu-lua/?.lua;' .. package.path

## Usage

Have a look at the examples to find out how to use Avandu Lua. Here is
a somewhat more general explanation.

### User credentials

In order to be able to log-in to Tiny Tiny RSS without asking the user
for the credentials each time the program is run, this information is
stored in `$HOME/.avandu.json`. This file should contain a single JSON
object containing a `user` and a `password` field, such as:

    {'user': 'USERNAME', 'password': 'PASSWORD'}

Please make sure that this file is readable and writable only by you.

### Load it

As is usually the case with libraries, before you can use them you
must load them, this holds true for Avandu as well.

        local avandu = require 'avandu'

### Set the Tiny Tiny RSS URL

The default value of `avandu.ttrss_url` is `nil`, which won't help you
if you're trying to connect, so before you can actually call any of
the functions you should tell Avandu where your Tiny Tiny RSS's API
can be accessed.

        avandu.ttrss_url = 'https://example.com/tt-rss/api/'

