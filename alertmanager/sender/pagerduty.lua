local time = require("time")
local storage = require("storage")
local http = require("http")
local json = require("json")
local crypto = require("crypto")

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


local http_client = http.client({})
local function send(info)
  local jsonb, err = json.encode(info)
  if err then error(err) end
  local request, err = http.request("POST", "https://events.pagerduty.com/v2/enqueue", jsonb)
  if err then error end
  request:header_set("Content-Type", "application/json")
  request:header_set("Accept", "application/vnd.pagerduty+json;version=2")
  request:header_set("Authorization", "Token token="..os.getenv("PAGERDUTY_TOKEN"))
  local result, err = http_client:do_request(request)
  if err then error(err) end
end

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
        local info, err = json.encode(row[3])
        if err then error(err) end
        local jsonb = {
          routing_key = config.senders.pagerduty.rk[severity],
          dedup_key = crypto.md5(row[1]..host),
          payload = {
            summary = row[1] .. " on host " .. host,
            severity = severity,
            component = "postgresql",
            custom_details = info.custom_details
          }
        }
        send(jsonb)
      end
    end
  end
end

helpers.runner.run_every(collect, 10)
