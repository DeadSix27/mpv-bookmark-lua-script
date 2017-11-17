local assdraw = require "mp.assdraw"

--// Save/Load string serializer function
function exportstring( s )
  return string.format("%q", s)
end

--// The Save Function [copied from http://lua-users.org/wiki/SaveTableToFile]
function saveTable(  tbl,filename )
  local charS,charE = "   ","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  file:write( "return {"..charE )

  for idx,t in ipairs( tables ) do
    file:write( "-- Table: {"..idx.."}"..charE )
    file:write( "{"..charE )
    local thandled = {}

    for i,v in ipairs( t ) do
      thandled[i] = true
      local stype = type( v )
      -- only handle value
      if stype == "table" then
        if not lookup[v] then
          table.insert( tables, v )
          lookup[v] = #tables
        end
        file:write( charS.."{"..lookup[v].."},"..charE )
      elseif stype == "string" then
        file:write(  charS..exportstring( v )..","..charE )
      elseif stype == "number" then
        file:write(  charS..tostring( v )..","..charE )
      end
    end

    for i,v in pairs( t ) do
      -- escape handled values
      if (not thandled[i]) then

        local str = ""
        local stype = type( i )
        -- handle index
        if stype == "table" then
          if not lookup[i] then
            table.insert( tables,i )
            lookup[i] = #tables
          end
          str = charS.."[{"..lookup[i].."}]="
        elseif stype == "string" then
          str = charS.."["..exportstring( i ).."]="
        elseif stype == "number" then
          str = charS.."["..tostring( i ).."]="
        end

        if str ~= "" then
          stype = type( v )
          -- handle value
          if stype == "table" then
            if not lookup[v] then
              table.insert( tables,v )
              lookup[v] = #tables
            end
            file:write( str.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
            file:write( str..exportstring( v )..","..charE )
          elseif stype == "number" then
            file:write( str..tostring( v )..","..charE )
          end
        end
      end
    end
    file:write( "},"..charE )
  end
  file:write( "}" )
  file:close()
end

--// The Load Function [copied from http://lua-users.org/wiki/SaveTableToFile]
function loadTable( sfile )
  local ftables,err = loadfile( sfile )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
    local tolinki = {}
    for i,v in pairs( tables[idx] ) do
      if type( v ) == "table" then
        tables[idx][i] = tables[v[1]]
      end
      if type( i ) == "table" and tables[i[1]] then
        table.insert( tolinki,{ i,tables[i[1]] } )
      end
    end
    -- link indices
    for _,v in ipairs( tolinki ) do
      tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
    end
  end
  return tables[1]
end

--// default file to save/load bookmarks to/from
function getConfigFile()
  return os.getenv('APPDATA') .. "\\mpv-bookmarks.json"
end

--// check whether a file exists or not
function file_exists(path)
  local f = io.open(path,"r")
  if f~=nil then
    io.close(f)
    return true
  else
    return false
  end
end

--// save current file/pos to a bookmark object
function currentPositionAsBookmark()
  local bookmark = {}
  bookmark["pos"] = mp.get_property_number("time-pos")
  bookmark["filepath"] = mp.get_property("path")
  bookmark["filename"] = mp.get_property("filename")
  return bookmark
end

--// play to a bookmark
function bookmarkToCurrentPosition(bookmark, tryToLoadFile)
  if mp.get_property("path") == bookmark["filepath"] then -- if current media is the same as bookmark media
    mp.set_property_number("time-pos", bookmark["pos"])
    return
  elseif tryToLoadFile == true then
    mp.commandv("loadfile", bookmark["filepath"], "replace")
    local seekerFunc = {}
    seekerFunc.fn = function()
      mp.unregister_event(seekerFunc.fn);
      bookmarkToCurrentPosition(bookmark, false)
    end
    mp.register_event("playback-restart", seekerFunc.fn)
  end
end

function timestamp(duration)
    -- mpv may return nil before exiting.
    if not duration then return "" end
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%06.03f", hours, minutes, seconds)
end

function clear_ass_text()
    mp.set_osd_ass(0, 0, "")
end

function draw_ass_text(text)
	ass = assdraw.ass_new()
	ass:pos(0, 0)
	ass:append(text)
	mp.set_osd_ass(0, 0, ass.text)
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- local inspect = require 'inspect' # for debugging

function getSafeString(array,key)
  local arrayKey = array[key]
	if arrayKey == nil then
		return "-"
	else
		return arrayKey
	end
end
function getSafeInt(array,key)
  local arrayKey = array[key]
	if arrayKey == nil then
		return 0
	else
		return arrayKey
	end
end

local displayListCountdownElapsed = 6
local displayListString = ""

displayListCountdown = mp.add_periodic_timer(1, function()
    displayListCountdownElapsed = displayListCountdownElapsed + 1
    if displayListCountdownElapsed >= 5 then
        displayListCountdown:kill()
				clear_ass_text()
    else
			draw_ass_text(string.format("%s\\N\\h\\hHiding in %d ..",displayListString, 5 - displayListCountdownElapsed) )
		end
end)

function unichr(ord)
    if ord == nil then return nil end
    if ord < 32 then return string.format('\\x%02x', ord) end
    if ord < 126 then return string.char(ord) end
    if ord < 65539 then return string.format("\\u%04x", ord) end
    if ord < 1114111 then return string.format("\\u%08x", ord) end
end

mp.register_script_message("bookmark-list", function(slot)
  local bookmarks, error = loadTable(getConfigFile())
	local curFileName = mp.get_property_osd("filename")
  if error ~= nil then
    mp.osd_message("Error: " .. error)
    return
  end
	displayListString = "{\\fnSource Sans Pro\\b1\\fs12\\bord0.7\\c&HFFFFFF&\\1a&H00&\\3c&H000000&\\3a&H00&\\4c&H000000&\\4a&HFF&}\\h\\N\\h\\hBookmark list:\\N"
	local bookmarkCount = tablelength(bookmarks)
	print("List of bookmarks:")
	for i=1,bookmarkCount,1
	do
		local fileName = getSafeString(bookmarks[tostring(i)],"filename")
		local path     = getSafeString(bookmarks[tostring(i)],"filepath")
		local pos      = getSafeInt(bookmarks[tostring(i)],"pos")
		local preSpace = "\\h{\\1a&HFF&\\3a&HFF&}" .. "►" .. "{\\1a&H00&\\3a&H00&}\\h"
		if string.lower(fileName) == string.lower(curFileName) then
			preSpace = "\\h{\\1a&H00&\\3a&H00&}" .. "►" .. "{\\1a&H00&\\3a&H00&}\\h"
		end
		print(string.format("[%d] %s [%s]\\N", i, fileName, timestamp(pos)))
		displayListString = displayListString .. string.format("%s[Alt-%d] %s [%s]\\N",preSpace, i, fileName, timestamp(pos))
	end

	ass = assdraw.ass_new()
	ass:pos(0, 0)
	ass:append(displayListString .. "\\N\\h\\hHiding in 5 ..")
	mp.set_osd_ass(0, 0, ass.text)

	displayListCountdownElapsed = 0
	displayListCountdown:resume()
end)

--// handle "bookmark-set" function triggered by a key in "input.conf"
mp.register_script_message("bookmark-set", function(slot)
  print("Saving " .. slot )
  local bookmarks, error = loadTable(getConfigFile())
  if error ~= nil then
    bookmarks = {}
  end
  bookmarks[slot] = currentPositionAsBookmark()
  local result = saveTable( bookmarks, getConfigFile())
  if result ~= nil then
    mp.osd_message("Error saving: " .. result)
  end
  mp.osd_message("Bookmark#" .. slot .. " saved.")
end)

--// handle "bookmark-load" function triggered by a key in "input.conf"
mp.register_script_message("bookmark-load", function(slot)
  local bookmarks, error = loadTable(getConfigFile())
  if error ~= nil then
    mp.osd_message("Error: " .. error)
    return
  end
  local bookmark = bookmarks[slot]
  if bookmark == nil then
    mp.osd_message("Bookmark#" .. slot .. " is not set.")
    return
  end
  if file_exists(bookmark["filepath"]) == false then
    mp.osd_message("File " .. bookmark["filepath"] .. " not found!")
    return
  end
  bookmarkToCurrentPosition(bookmark, true)
  mp.osd_message("Bookmark#" .. slot .. " loaded.")
end)
