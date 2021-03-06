## mpv-bookmarker ![Alt text](https://github.com/mpv-player/mpv/raw/master/etc/mpv-icon-8bit-32x32.png)

#### mpv-bookmarker is a lua script for mpv to to set bookmark on your favorite moments of certain media files 

###### Usage
* Copy `bookmarker.lua` script to `~/.config/mpv/scripts/bookmarker.lua`
* Open key configuration file at `~/.config/mpv/input.conf` and 
  map your desired keys to save/load a specific bookmark. For example the lines below mean `Ctrl+1` will "save current filePath and seekPos to bookmark #1 slot" and `Alt+2` will "restore current filePath and seekPos from bookmark #2 slot"  
```    
Ctrl+1 script_message bookmark-set  1
Alt+1  script_message bookmark-load 1
Ctrl+2 script_message bookmark-set  2
Alt+2  script_message bookmark-load 2
```
* There is no limit to slots. (the whole bookmark data will be kept in file `~/.config/mpv/bookmarks.json`)

###### Tested
* Has been tested on Windows ([Original](https://github.com/nimatrueway/mpv-bookmark-lua-script) has been tested on MacOS/Linux)

##### Modifications by @DeadSix27

Added crude bookmark list display (ctrl-b):

![BookmarklistScreenshot](bookmarklistscreenshot.png?raw=true "BookmarklistScreenshot")
