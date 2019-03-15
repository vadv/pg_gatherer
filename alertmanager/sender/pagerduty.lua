local time = require("time")
local storage = require("storage")


local helpers = dofile(os.getenv("CONFIG_INIT"))
local config = helpers.config.load(os.getenv("CONFIG_FILENAME"))
local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end

if not(config.senders.pagerduty) or not(config.senders.pagerduty.enabled) then
  print("disable pagerduty sender")
  while true do
    -- disable pagerduty
    time.sleep(60)
  end
end

print("start pagerduty sender")

local cache, err = storage.open(config.cache_path)
if err then error(err) end

local stmt, err = manager:stmt("select key, severity, info, created_at from manager.alert where host = $1")
if err then error(err) end

local function collect()
  for _, host in pairs(get_hosts()) do
    local result, err = stmt:query(host)
    if err then error(err) end
    for _, row in pairs(result.rows) do
      local cache_key = host .. row[1]
      local _, found, err = cache:get(cache_key)
      if err then error(err) end

      if not found then
        -- send
        print("host", host, "key", row[1], "severity", row[2], "info", row[3], "created_at", row[4])
      end
    end
  end
end

helpers.runner.run_every(collect, 10)
