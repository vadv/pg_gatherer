local time = require("time")
local storage = require("storage")


local helpers = dofile(os.getenv("CONFIG_INIT"))
local config = helpers.config.load(os.getenv("CONFIG_FILENAME"))
local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end

if not(config.senders.pagerduty) or not(config.senders.pagerduty.enabled) then
  while true do
    -- disable pagerduty
    time.sleep(60)
  end
end

print("start pagerduty sender")

local cache, err = storage.open(config.cache_path)
if err then error(err) end

local function collect()
end

helpers.runner.run_every(collect, 10)
