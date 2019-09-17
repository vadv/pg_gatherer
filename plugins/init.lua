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
-- this function run in plugin context, then we use cache key `last_run`
function run_every(f, every)
  while true do

    local _, updated_at = cache:get("last_run")
    if time.unix() >= updated_at + every then
      local start_at = time.unix()
      f()
      cache:set("last_run", 0)
      local exec_time = (time.unix() - start_at)
      if exec_time > every then
        print(debug.getinfo(2).source, "execution timeout:", exec_time)
        time.sleep(1)
      end
    else
      -- wait
      time.sleep(1)
    end

  end
end