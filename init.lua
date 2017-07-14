function prolog()
  if file.exists("prolog.lua") then
    print("Running prolog.lua")
    dofile("prolog.lua")
  else
    print("Skipping prolog")
  end
end

function payload()
--  print("startup heap free:", node.heap())
  if file.exists("init.lua") == false then
    print("init.lua deleted or renamed")
  else
    print("Running")
    -- the actual application is stored in 'payload.lua'
    if file.exists("payload.lua") == false then
      print("payload.lua not found")
    else
      print("Starting payload...")
      dofile("payload.lua")
    end
  end
end

countdown_count = 10
countdown = tmr.create()
print("Startup will resume momentarily, you have " .. countdown_count .. " seconds to abort.")
countdown:alarm(1000, tmr.ALARM_AUTO, function()
  print("  " .. countdown_count .. " ...")
  countdown_count = countdown_count - 1
  if countdown_count <= 0 then
    print("Resuming startup")
    countdown:unregister()
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
      print("Initializing")
      prolog()
      print("Initialized")
      print("Starting")
      payload()
      print("Started")
    end)
  end
end)
