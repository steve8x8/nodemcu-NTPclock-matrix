-- ESP8266 payload to drive a LED matrix display
-- using NTP time

-- UTC offset
--local UTC_OFFSET = 7200
dofile("utc_offset.lua")

domino3 = require("domino3")

-- helper function
local function sntpsync()
  sntp.sync({"pool.ntp.org", "194.94.224.118", "ptbtime1.ptb.de"},
    function(sec, usec, server, info) -- success callback
      print("SNTP success")
      print("server " .. server)
      max7219.write({0x3c, 0x42, 0x3c, 0x00, 0x7e, 0x28, 0x44, 0x02}) -- OK
    end,
    function(errno, errstr) -- error callback
      print("SNTP failure")
      print("error " .. tostring(errno) .. ": " .. tostring(errstr))
      max7219.write({0x7e, 0x30, 0x0c, 0x7e, 0x00, 0x3c, 0x42, 0x3c}) -- NO
    end)
end


-- MAX7219 init done in prolog()

if payload_started == nil then
  -- do not recreate timers
  payload_started = true
  -- set a time to refresh clock periodically
  tmr.create():alarm(3600000, tmr.ALARM_AUTO, function()
    sntpsync()
  end)
  -- refresh time if there's any
  tmr.create():alarm(500, tmr.ALARM_AUTO, function()
    -- read time
    local sec, msec = rtctime.get()
    -- RTC must be primed
    if (sec ~= 0) then
      -- convert into readable
      local tm = rtctime.epoch2cal(sec + UTC_OFFSET)
      local ul = domino3.getDomino(tm["hour"]/10)
      local ur = domino3.getDomino(tm["hour"]%10)
      local bl = domino3.getDomino(tm["min"]/10)
      local br = domino3.getDomino(tm["min"]%10)
      -- merge into matrix
      local matrix = {0, 0, 0, 0, 0, 0, 0, 0}
      for i = 1, 3 do
        for j= 1, 3 do
          if ul[i][j] ~= 0 then
            matrix[i] = bit.set(matrix[i], j - 1)
          end
          if ur[i][j] ~= 0 then
            matrix[i + 5] = bit.set(matrix[i + 5], j - 1)
          end
          if bl[i][j] ~= 0 then
            matrix[i] = bit.set(matrix[i], j - 1 + 5)
          end
          if br[i][j] ~= 0 then
            matrix[i + 5] = bit.set(matrix[i + 5], j -1 + 5)
          end
        end
      end
      -- set more bits???
      max7219.write(matrix)
    end
  end)
end

-- wificonnect (defined in wifi.lua) must be reentrant!
-- initialize network
wificonnect(function()
  print("Wifi connect callback")
  if (wifi.sta.status() ~= 5) then
    print("no WiFi, status " .. wifi.sta.status())
    max7219.write7segment("No netwk")
  else
    -- if using MPIGUEST, authenticate first
    local apinfo = wifi.sta.getapinfo()
    local ssid = apinfo[1]["ssid"]
    print("Connected to " .. ssid)
    if (file.exists(ssid .. "-login.lua")) then
      print("Authenticate " .. ssid)
      max7219.clear()
      max7219.write7segment(ssid)
      -- fake authentication
      dofile(ssid .. "-login.lua")
      print("Done")
    end
    -- set clock to continue
    tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()
      print("Initial SNTP")
      max7219.write7segment("SNTP ---")
      sntpsync()
    end)
  end
end)
