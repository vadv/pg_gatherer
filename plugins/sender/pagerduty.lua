local token       = secrets:get("pagerduty_token")
local key_default = secrets:get("pagerduty_key_default")

if not (token) or not (key_default) then
  return function() end
end

plugin_log:printf("[INFO] start pagerduty sender\n")

-- load routing rules
local routing_file = filepath.join(plugin:dir(), "pagerduty_routing.lua")
if goos.stat(filepath.join(plugin:dir(), "pagerduty_routing_overrides.lua")) then
  routing_file = filepath.join(plugin:dir(), "pagerduty_routing_overrides.lua")
end
local get_routing = dofile(routing_file)

local http        = require("http")
local crypto      = require("crypto")
local http_client = http.client({})
local sql         = read_file_in_plugin_dir("list_of_alerts.sql")

local function send(info)
  local jsonb, err = json.encode(info)
  if err then error(err) end
  plugin_log:printf("[INFO] send to pagerduty: %s\n", jsonb)
  local request, err = http.request("POST", "https://events.pagerduty.com/v2/enqueue", jsonb)
  if err then error(err) end
  request:header_set("Content-Type", "application/json")
  request:header_set("Accept", "application/vnd.pagerduty+json;version=2")
  request:header_set("Authorization", "Token token=" .. token)
  local result, err = http_client:do_request(request)
  if err then error(err) end
  if result.code > 300 then
    error("response : " .. inspect(result))
  end
end

local function process_alert_row(alert)
  local cache_key     = alert.host .. alert.key .. "pagerduty"
  local _, silence_to = cache:get(cache_key)
  silence_to          = silence_to or 0
  if time.unix() > silence_to then
    local routing = get_routing(alert)
    local jsonb   = {
      routing_key  = routing.key,
      dedup_key    = crypto.md5(alert.key .. alert.host),
      event_action = "trigger",
      payload      = {
        summary        = alert.key .. " [" .. alert.host .. "]",
        source         = "pg_gatherer for " .. alert.host,
        severity       = routing.severity,
        component      = "postgresql",
        custom_details = json.decode(alert.custom_details)
      }
    }
    send(jsonb)
    silence_to = time.unix() + 5 * 60
    cache:set(cache_key, silence_to)
  end
end

return process_alert_row()
