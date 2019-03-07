local time = require("time")
local storage = require("storage")

local db = storage.open(os.getenv("CONFIG_STORAGE"), "disk")

local function save(key, value)
  local data = {value = value, unixts = time.unix()}
  local err = db:set(key, data, 2*60*60)
  if err then error(err) end
end

local function diff(key, value)

  if not value then return nil end

  local now = time.unix()

  local prev, found, err = db:get(key)
  if err then error(err) end
  if not found then
    save(key, value)
    return
  end

  -- overflow
  if prev.value > value then
    save(key, value)
    return
  end

  save(key, value)

  return value - prev.value
end

return diff
