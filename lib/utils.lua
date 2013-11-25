-------------------------------------------
-- Various utility functions and constants
-- Some of these are mine (Lerg), some I found on the net
-- Release date: 2011-08-25
-- Version: 1.0
-- License: MIT I guess, at least my part
-------------------------------------------


local mRandom = math.random
local tInsert = table.insert
local app = require('lib.app')
-------------------------------------------
-- Shuffle a table
-------------------------------------------
table.shuffle = function (t)
  local n = #t
  while n > 2 do
    -- n is now the last pertinent index
    local k = mRandom(1, n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
end

function table.deepcopy(t)
    if type(t) ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = table.deepcopy(v)
        end
        res[k] = v
    end
    setmetatable(res,mt)
    return res
end

function trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

function startswith (s, piece)
    return string.sub(s, 1, string.len(piece)) == piece
end

function endswith(s, send)
    return #s >= #send and s:find(send, #s-#send+1, true) and true or false
end

-------------------------------------------
-- split(string, separator)
-------------------------------------------
function split(p,d)
  local t, ll, l
  t={}
  ll=0
  if(#p == 1) then return {p} end
    while true do
      l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        tInsert(t, string.sub(p,ll,l-1)) -- Save it in our array.
        ll=l+1 -- save just after where we found it for searching next time.
      else
        tInsert(t, string.sub(p,ll)) -- Save what's left in our array.
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
  return t
end

-------------------------------------------
-- Set a value to bounds
-------------------------------------------
function clamp(value, low, high)
    if value < low then value = low
    elseif high and value > high then value = high end
    return value
end

-------------------------------------------
-- Check if a value in the bounds
-------------------------------------------
function inBounds(value, low, high)
    if value >= low and value <= high then
        return true
    else
        return false
    end
end

-------------------------------------------
-- Print two dimensional arrays
-------------------------------------------
function print2d(t)
    for r = 0, table_len(t) - 1 do
        local str = ''
        for c = 0, table_len(t[r]) - 1 do
            local val = t[r][c] or 0
            val = round(val)
            if val == 0 then
                val = ' '
            end
            str = str .. val .. ' '
        end
        print(str)
    end
end

-------------------------------------------
-- Number rounding
-------------------------------------------
function math.round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

-------------------------------------------
-- Save specified value to specified file
-------------------------------------------
function saveFile(strFilename, strValue, dir)
    local path = system.pathForFile(strFilename, dir or system.DocumentsDirectory)
    local file = io.open( path, "w+" )
    if file then
       file:write(strValue)
       io.close(file)
    end
end

-------------------------------------------
-- Load specified file, or create new file if it doesn't exist
-------------------------------------------
function readFile(strFilename, dir)
    local theFile = strFilename
    local path = system.pathForFile( theFile, dir or system.DocumentsDirectory )
    -- io.open opens a file at path. returns nil if no file found
    local file = io.open( path, "r" )
    if file then
       -- read all contents of file into a string
       local contents = file:read( "*a" )
       io.close( file )
       return contents
    else
       return ''
    end
end


-------------------------------------------
-- Check if the value is in array or sequence of arguments
-- USAGE: checkIn(value, table) OR
--        checkIn(value, arg1, arg2, arg3 ... )
-------------------------------------------
function checkIn(value, ...)
    if type(arg[1]) == 'table' then
        for k, v in pairs(arg[1]) do
            if v == value then
                return true
            end
        end
    else
        for i, v in ipairs(arg) do
            if v == value  then
                return true
            end
        end
    end
    return false
end

function datetime()
    local t = os.date('*t')
    return t.year .. '-' .. t.month .. '-' .. t.day .. ' ' .. t.hour .. ':' .. t.min .. ':' .. t.sec
end

function parse_datetime(datetime)
    local pattern = '(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)'
    local year, month, day, hour, minute, seconds = datetime:match(pattern)
    year = tonumber(year)
    month = tonumber(month)
    day = tonumber(day)
    return {year = year, month = month, day = day, hour = hour, min = minute, sec = seconds}
end

function pprint (t, name, indent)
  local tableList = {}
  local function table_r (t, name, indent, full)
    local serial=string.len(full) == 0 and name
        or type(name)~="number" and '["'..tostring(name)..'"]' or '['..name..']'
    print(indent,serial,' = ') 
    if type(t) == "table" then
      if tableList[t] ~= nil then print('{}; -- ',tableList[t],' (self reference)\n')
      else
        tableList[t]=full..serial
        if next(t) then -- Table not empty
          print('{\n')
          for key,value in pairs(t) do table_r(value,key,indent..'\t',full..serial) end 
          print(indent,'};\n')
        else print('{};\n') end
      end
    else print(type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"'
                  or tostring(t),';\n') end
  end
  table_r(t,name or '__unnamed__',indent or '','')
end

function HSVtoRGB(h, s, v)
    local r,g,b
    local i
    local f,p,q,t
    
    if s == 0 then
        r = v
        g = v
        b = v
        return r, g, b
    end
  
    h =   h / 60;
    i  = math.floor(h);
    f = h - i;
    p = v *  (1 - s);
    q = v * (1 - s * f);
    t = v * (1 - s * (1 - f));
    if i == 0 then        
        r = v
        g = t
        b = p
    elseif i == 1 then 
        r = q
        g = v
        b = p
    elseif i == 2 then 
        r = p
        g = v
        b = t
    elseif i == 3 then 
        r = p
        g = q
        b = v
    elseif i == 4 then 
        r = t
        g = p
        b = v
    elseif i == 5 then 
        r = v
        g = p
        b = q
    end
    return r, g, b
end