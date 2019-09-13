local time = require("time")

local value, err = cache:get("unknown")
if err then error(err) end
if value then error("must be unknown") end

-- set get
local err = cache:set("value_set_get", 42)
if err then error(err) end
local value_set_get, err = cache:get("value_set_get")
if err then error(err) end
if not(value_set_get == 42) then error("value_set_get must be 42, but get: "..tostring(value_set_get)) end

-- check diff
local err = cache:set("value_diff", 0)
if err then error(err) end
local diff, err = cache:diff_and_set("value_diff", 1)
if not(diff == 1) then error("diff must be 1, but get: "..tostring(diff)) end
local diff, err = cache:get("value_diff")
if err then error(err) end
if not(diff == 1) then error("diff must be 1, but get: "..tostring(diff)) end

-- check speed
local err = cache:set("value_speed", 0)
if err then error(err) end
time.sleep(1)
local speed, err = cache:speed_and_set("value_speed", 1)
if speed == 0 then error("speed: "..tostring(speed)) end
if not(speed > 0) then error("speed: "..tostring(speed)) end
local speed, err = cache:get("value_speed")
if err then error(err) end
if not(speed == 1) then error("diff must be 1, but get: "..tostring(speed)) end