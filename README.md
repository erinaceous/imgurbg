imgurbg.sh: Download a random image from multiple imgur albums and make it your
wallpaper :)

![tiny demonstration gif](http://i.imgur.com/xleGFRx.gif "Tiny demonstration gif")

Requirements:
=============
* curl or wget
* jshon -> http://kmkeen.com/jshon/
* A program to set your desktop wallpaper (defaults to 'feh')

Quick usage
===========
First of all, you need to get yourself a 'Client ID' for use with the imgur API.
* Log in to imgur.com (register if you don't have an account), then go to this
page: https://api.imgur.com/oauth2/addclient
    * "Authorization Type" could be "Anonymous usage without user authorization"
      -- that's what I used.
    * Although you don't need a callback URL, it still asks for one. Set it to a
      random URL like http://devnull.com or something.
    * Email address & description fields also need to be filled in, set them to
      whatever.
* Once you've done that, it'll give you a "Client ID" and "Client Secret" on the
  next page, and will also email you them. You just need the Client ID for the
  purposes of this script.
* Should you forget your Client ID, you can find it again on this page:
  https://imgur.com/account/settings/apps

Next, if you don't wanna clone this repo, you can just run these commands:

    mkdir ~/.imgurbg-cache
    cd .imgurbg-cache
    wget -O imgurbg.sh https://raw.github.com/doomcat/imgurbg/master/imgurbg.sh 
    ./imgurbg.sh --api_key [Client ID] akHsJ

This will download the script into .imgurbg-cache and run it using the API key
specified. The second argument (`akHsJ`) is the ID of an imgur album, so you can
change it to whatever album you want. That album is nice though:
http://s.imgur.com/a/akHsJ

(You can also specify multiple albums)

It will then call the imgur API to get the list of images for the selected
albums, and pick one random image from one of them. It will download it to
.imgurbg-cache if it hasn't previously been downloaded.

If you don't want to keep passing the script your Client ID every time, create a
`~/.imgurbg-cache/config` file which contains

    CLIENT_ID='Your Client ID'

PROTIP: set it up to pick a new wallpaper every 15 minutes with this script:

    #!/bin/bash
    while true; do
        ~/.imgurbg-cache/imgurbg.sh
        sleep 15m
    done

And adding that to your desktop environment's startup programs.

You can blacklist images from showing up (couple of wallpapers too NSFW?) by
creating a 'blacklist.txt' in the root of your cache directory
(So by default that's `~/.imgurbg-cache/blacklist.txt`), and adding the URLs of
the files you DON'T want to download, one per line.

Enjoy all the pretty and enormous imgur albums of 1080p+ wallpapers out there :)
