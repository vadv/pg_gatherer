local time = require("time")

local data = {
  -- key = {value = value, unixts = unixts}
}

local function speed(key, value)
  if not value then return nil end
  local prev = data[key]
  local now = time.unix()
  data[key] = { value = value, unixts = now }
  -- first run
  if not prev then return nil end
  -- overflow
  if prev.value > value then return nil end
  -- calc
  local time_diff = now - prev.unixts
  local value_diff = value - prev.value
  -- value
  return (value_diff / time_diff)
end

return speed
