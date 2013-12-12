#!/bin/bash
# imgurbg.sh: Owain Jones [github.com/doomcat]
# Uses the Imgur API to fetch a random image from a specified album.
#
# Requirements:
# curl or wget
# jshon: http://kmkeen.com/jshon/
# Program for setting your desktop wallpaper. Default is 'feh'.
#
# To use this, you need to give the script an API Key also (You can
# set the default key in this script in the API_KEY variable).
# To generate an API key, log in to imgur.com (register if you don't have
# an account) and go to this page: https://api.imgur.com/oauth2/addclient
# "Authorization Type" should be "Anonymous usage without user authorization".
# Although you don't need a callback URL, it still asks for one. Set it to a
# random URL like http://devnull.com or something.
# Email address & description fields also need to be filled in, set them to
# whatever.
# Once you've done that, it'll give you a "Client ID" and "Client Secret"
# (which it'll show on the next page, as well as email you with). You just need
# the Client ID for the purposes of this script.
# Should you forget your Client ID, you can find it on this page:
# https://imgur.com/account/settings/apps

# Some defaults
API_KEY="None, please edit this file or pass via command line argument."
WALLPAPERER="/usr/bin/feh --bg-fill %s"
SAVE_TO="$HOME/.imgurbg-cache/%s"
ALBUMS=""  # you could set default album ID(s) here.
API_URL="https://api.imgur.com/3/gallery/album/%s.json"

# Persistent config file which can override the above variables
save_root=${SAVE_TO//\/%s/}
if [ -f "$save_root/config" ]; then
    source "$save_root/config"
fi

function usage() {
cat <<HELP
Downloads a random image from an imgur album, and sets it as your wallpaper.
Usage:
    $0 [--api-key API_KEY] [--wallpaperer COMMAND] [--save-to DIR] [album-ID, album-ID, ...]
    Where 'API_KEY' is the Client ID for your application.
    Your default API_KEY: $API_KEY
    album-ID is the ID of the album, example:
        http://s.imgur.com/a/akHsJ
        'akHsJ' is the ID of this album
    
    '--wallpaperer COMMAND' lets you specify the command to use to set your
    desktop wallpaper to the downloaded image.
    The default is: $WALLPAPERER
    (The '%s' in the command will be substituted with the path of the downloaded
     image)

    '--save-to DIR' lets you specify the directory into which to save your
    downloaded wallpapers, in case you want to keep a copy of them.
    The default is: $SAVE_TO
    (If you've left the default as /tmp/imgurbg-cache, you will lose your
     downloaded wallpapers everytime you shut down your computer.)
HELP
exit 1
}

# Check the command line arguments for instances of -h, -H, --help, etc.
if [ "`echo $* | grep -i -c -P '\-*(h|help)\b'`" != "0" ]; then
    usage
fi

# Parse the command line arguments.
while [ "$#" -ge "1" ]; do
    if [ "${1:0:2}" = "--" ]; then
        case $1 in
            --api-key)
                API_KEY="$2"
                shift ;;
            --wallpaperer)
                WALLPAPERER="$2"
                shift ;;
            --save-to)
                SAVE_TO="$2"
                shift ;;
            *)
                echo "Unknown argument on command line."
                usage
        esac
    else
        ALBUMS="$ALBUMS$1 "
    fi
    shift
done

# Check if album IDs have been passed on the command line or in the config
# file. If they haven't, default to using the IDs of albums previously used
# that have been stored in the cache directory -- find all directories within
# the cache dir whose names don't begin with '.' and treat them as album IDs.
if [ "$ALBUMS" = "" ]; then
    echo "No albums specified on command line (or in the script)."
    ALBUMS="`find $save_root -type d | xargs -n1 basename | grep -v -P '^\.'`"
    if [ "$ALBUMS" = "" ]; then
        echo "No previous albums found in $save_root either. Exiting :("
        exit 1
    else
        echo "Using albums: $ALBUMS"
    fi
fi

# Check for the curl or wget programs. If neither exist, we can't do any
# downloading so quit the script.
which curl > /dev/null 2>&1
if [ "$?" != "0" ]; then
    which wget > /dev/null 2>&1
    if [ "$?" != "0" ]; then
        echo "Couldn't find curl or wget in your PATH. Exiting :("
        exit 1
    else
        DOWNLOADER="wget"
    fi
else
    DOWNLOADER="curl"
fi

# Also look for the jshon program.
which jshon > /dev/null 2>&1
if [ "$?" != "0" ]; then
    echo "Couldn't find jshon program in your PATH. Exiting :("
    exit 1
fi

# If the cache dir doesn't exist yet, create it. Make sure it's not a file
# first. mkdir should fail anyway if the file exists but whatever.
if [ ! -d "$save_root" ]; then
    if [ ! -e "$save_to" ]; then
        echo "Creating directory $save_root"
        mkdir -p "$save_root"
        if [ "$?" != "0" ]; then
            echo "Couldn't create directory $save_root - Exiting :("
            exit 1
        fi
    else
        echo "$save_root already exists and is a regular file. Exiting :("
        exit 1
    fi
fi

# Loop through the list of album IDs. For each ID, check whether it's been
# cached -- check whether album.txt exists (which is a list of image URLs)
# within each album's directory. If it doesn't exist, call the imgur API to get
# that album's info. The response will be in JSON, so decode it using jshon and
# store the output as album.txt.
album_lists=""
for ALBUM in $ALBUMS; do
    save_to=${SAVE_TO//%s/$ALBUM}
    mkdir -p $save_to
    if [ ! -f "$save_to/album.txt" ]; then
        echo "Fetching album information"
        url="${API_URL//%s/$ALBUM}"
        if [ "$DOWNLOADER" = "wget" ]; then
            wget -q -O "$save_to/album.json" \
                --header "Authorization: Client-ID $API_KEY" $url 2>/dev/null
        elif [ "$DOWNLOADER" = "curl" ]; then
            curl -q -H "Authorization: Client-ID $API_KEY" \
                $url > "$save_to/album.json" 2>/dev/null
        fi
        jshon -e data -e images -a -e link -u \
            < "$save_to/album.json" > "$save_to/album.txt"
    fi
    album_lists="$album_lists$save_to/album.txt "
done

# Merge all the album.txt's from every album specified (via commandline/config,
# or found automatically), and pick one URL from the resulting giant list.
image=`echo -n $album_lists | xargs -d ' ' cat | sort -R | head -n1`
if [ "$image" = "" ]; then
    echo 'No images found in these albums. Exiting :('
    exit 1
fi

# Download that file if it doesn't exist in cache yet.
image_base=`basename $image`
image_file="$save_root/$image_base"
if [ ! -f "$image_file" ]; then
    echo "Downloading $image"
    if [ "$DOWNLOADER" = "wget" ]; then
        wget -q -O "$image_file" $image 2>/dev/null
    elif [ "$DOWNLOADER" = "curl" ]; then
        curl -q $image > $image_file 2>/dev/null
    fi
fi

# Finally, make it the wallpaper :)
echo "Picking $image_base"
if [ "$WALLPAPERER" != "" ]; then
    ${WALLPAPERER//%s/$image_file}
fi 
