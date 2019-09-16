local time = require("time")
-- set rotate table value = 2 sec
os.setenv("CACHE_ROTATE_TABLE", "2")

local err = cache:set("must_be_rotated_after_2_second", 1)
if err then error(err) end

time.sleep(1.5)
local value = cache:get("must_be_rotated_after_2_second")
if not(value == 1) then error("must be get from prev table") end

time.sleep(3)
local value = cache:get("must_be_rotated_after_2_second")
if value then error("table must be rotated") end