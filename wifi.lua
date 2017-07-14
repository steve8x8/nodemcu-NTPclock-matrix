-- WiFi connection handling

dofile("credentials.lua")

wifi_connected = false
wifi_function = nil

-- Define WiFi station event callbacks
wifi_connect_event = function(T)
  print("Connection to AP(".. T.SSID ..") established!")
  print("Waiting for IP address...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
  wifi_connected = true
end

wifi_got_ip_event = function(T)
  print("Wifi connection is ready! IP address is: " .. T.IP)
  print("Startup will resume momentarily, you have 3 seconds to abort.")
  print("Waiting...")
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
    print("Handing over to payload")
    tmr.create():alarm(2000, tmr.ALARM_SINGLE, wifi_function)
  end)
end

wifi_disconnect_event = function(T)
  wifi_connected = false
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    return
  end
  -- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
  local total_tries = 75
  print("\nWiFi connection to AP(" .. T.SSID .. ") has failed!")
  for key, val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
  print("Disconnect reason: " .. val .. "(" .. key .. ")")
      break
    end
  end
  if disconnect_ct == nil then
    disconnect_ct = 1
  else
    disconnect_ct = disconnect_ct + 1
  end
  if disconnect_ct < total_tries then
    print("Retrying connection...(attempt " .. (disconnect_ct+1) .. " of " .. total_tries .. ")")
  else
    wifi.sta.disconnect()
    print("Aborting connection to AP!")
    disconnect_ct = nil
  end
end

-- Register WiFi Station event callbacks
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)


-- the function to call in payload,
-- (reentrant!) callback continues once IP is set
function wificonnect(callback)
  wifi_function = callback
  if callback ~= nil then
    -- try to connect
    use_ssid = nil
    use_pass = nil
    print("Checking for available networks")
    wifi.setmode(wifi.STATION)
    wifi.sta.getap(1, function (t) -- (SSID : Authmode, RSSI, BSSID, Channel)
      for bssid, v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
        print("SSID " .. ssid .. " (" .. bssid .. " @ channel " .. channel .. ")")
        use_pass = CREDENTIALS[ssid]
        if (use_pass ~= nil) then
          print("Found known network " .. ssid)
          use_ssid = ssid
          break
        end
      end
      if (use_pass ~= nil) then
        print("Connecting to WiFi access point...")
        wifi.setmode(wifi.STATION)
        wifi.sta.config({ssid=use_ssid, pwd=use_pass, save=true})
        -- wifi.sta.connect() not necessary because config() uses auto-connect=true by default
      else
        print("No matching network found")
        -- startup()
      end
    end)
    use_ssid = nil
    use_pass = nil
  end
end
