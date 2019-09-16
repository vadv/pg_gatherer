-- this file loaded on first start of plugin

local filepath = require("filepath")
local time = require("time")
local inspect = require("inspect")
local json = require("json")
local ioutil = require("ioutil")

-- current directory (root)
root = filepath.dir(debug.getinfo(1).source)

-- return true if database hosted on rds
function is_rds()
  return not(not(
          pcall(function()
              connection:query("show rds.extensions")
          end)
  ))
end

-- run function f every sec
function run_every(f, every)
  while true do
    local start_at = time.unix()
    f()
    local sleep_time = every - (time.unix() - start_at)
    if sleep_time > 0 then
      time.sleep(sleep_time)
    else
      print(debug.getinfo(2).source, "execution timeout:", (time.unix() - start_at))
      time.sleep(1)
    end
  end
end