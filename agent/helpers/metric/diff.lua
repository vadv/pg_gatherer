local time = require("time")

local counter = 0
local data = {
  -- key = {value=value, unixts=now}
}

local function diff(key, value)

  if not value then return nil end
  local prev = data[key]
  local now = time.unix()
  data[key] = {value = value, unixts = now}

  -- first run
  if not prev then return nil end
  -- overflow
  if prev.value > value then return nil end

  -- compress
  counter = counter + 1
  if counter % 100 == 0 then
    local new_data = {}
    for key, v in pairs(data) do
      if now - 300 > v.unixts then new_data[key] = v end
    end
    data = new_data
  end

  return value - prev.value
end

return diff
