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

local function process_alert_row(row)
  local key, host                  = row[1], row[3]
  local custom_details, created_at = row[4], row[5]
  local cache_key                  = crypto.md5(host .. key .. "pagerduty")
  local _, silence_to              = cache:get(cache_key)
  silence_to                       = silence_to or 0
  if time.unix() > silence_to then
    local routing = get_routing(host, key, custom_details, created_at)
    local jsonb   = {
      routing_key  = routing.key,
      dedup_key    = crypto.md5(key .. host),
      event_action = "trigger",
      payload      = {
        summary        = key .. " [" .. host .. "]",
        source         = "pg_gatherer for " .. host,
        severity       = routing.severity,
        component      = "postgresql",
        custom_details = json.decode(custom_details)
      }
    }
    send(jsonb)
    silence_to = time.unix() + 5 * 60
    cache:set(cache_key, silence_to)
  end
end

-- process function
local function process()
  local result = storage:query("select name from host where not maintenance")
  for _, rowHost in pairs(result.rows) do
    local host   = rowHost[1]
    local result = storage:query(sql, host, get_unix_ts(storage))
    for _, row in pairs(result.rows) do
      local status, err = pcall(process_alert_row, row)
      if not status then
        plugin_log:printf("[ERROR] while process row %s plugin '%s' on host '%s' error: %s\n", inspect(row), plugin:name(), plugin:host(), err)
      end
    end
  end
end

return process()