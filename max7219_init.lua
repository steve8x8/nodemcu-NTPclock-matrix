-- initialize MAX7219 display
max7219 = require("max7219")
max7219.setup({numberOfModules = 1, slaveSelectPin = 8, intensity = 2}) -- no scrolling
--max7219.clear()
--max7219.shutdown(true)
--max7219.shutdown(false)
-- light up all matrix dots
max7219.write({{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}})
