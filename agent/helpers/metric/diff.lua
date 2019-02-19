local time = require("time")

local data = {
  -- key = value
}

local function diff(key, value)
  if not value then return nil end
  local prev = data[key]
  local now = time.unix()
  data[key] = value
  -- first run
  if not prev then return nil end
  -- overflow
  if prev > value then return nil end

  return value - prev
end

return diff
