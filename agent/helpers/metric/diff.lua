local time = require("time")
local storage = require("storage")
local crypto = require("crypto")

local db, err = storage.open(os.getenv("CACHE_PATH"), "badger")
if err then error(err) end

local function save(key, value)
  local data = {value = value, unixts = time.unix()}
  local err = db:set(key, data, 60*60)
  if err then error(err) end
end

local function diff(key, value)

  if not value then return nil end

  local now = time.unix()
  local hash_key = crypto.md5(key)

  local prev, found, err = db:get(hash_key)
  if err then error(err) end
  if not found then
    save(hash_key, value)
    return
  end

  -- overflow
  if prev.value > value then
    save(hash_key, value)
    return
  end

  save(hash_key, value)

  return value - prev.value
end

return diff
