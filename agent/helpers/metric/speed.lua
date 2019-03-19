local time = require("time")
local crypto = require("crypto")

local last_gc = time.unix()
local data = {
  -- key = {value = value, unixts = unixts}
}

local function speed(key, value)

  local hash_key = crypto.md5(key)

  if not value then return nil end
  local prev = data[hash_key]
  local now = time.unix()
  data[hash_key] = { value = value, unixts = now }
  -- first run
  if not prev then return nil end
  -- overflow
  if prev.value > value then return nil end
  -- calc
  local time_diff = now - prev.unixts
  local value_diff = value - prev.value

  -- compress
  if now - 360 > last_gc then
    local old_size, new_size = 0, 0
    local new_data = {}
    for hash_key, v in pairs(data) do
      old_size = old_size + 1
      if v.unixts > now - 10*60 then
        new_size = new_size + 1
        new_data[hash_key] = v
      end
    end
    print("speed db compressed, old size:", old_size, "new size: ", new_size)
    data = new_data
    collectgarbage()
    last_gc = now + math.random(60)
  end

  -- value
  return (value_diff / time_diff)
end

return speed
