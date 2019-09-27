local token   = secrets:get("telegram_token")
local chat_id = secrets:get("telegram_chat_id")
if chat_id then chat_id = tonumber(chat_id) end

if not (token) or not (chat_id) then
  return function() end
end

plugin_log:printf("[INFO] start telegram sender\n")

local sql           = read_file_in_plugin_dir("list_of_alerts.sql")
local telegram      = require("telegram")
local http          = require("http")
local client        = http.client({})
local template      = require("template")

local mustache, err = template.choose("mustache")
if err then error(err) end

local telegram_bot                     = telegram.bot(token, client)
local telegram_message_firing_template = [[
🔥 <b>FIRING</b> 🔥
Host:              {{ host }}
Problem:        {{ key }}
Created:        {{ created_at }}
Description:  <code>{{ description }}</code>
]]

local function process_alert_row(row)
  local key, ts, host              = row[1], row[2], row[3]
  local custom_details, created_at = row[4], row[5]
  local cache_key                  = key .. host .. "telegram"
  local silence_to                 = cache:get(cache_key)
  silence_to                       = silence_to or 0

  -- send message
  if time.unix() > silence_to then
    created_at    = created_at or ts
    local alert   = {
      host        = host,
      key         = key,
      created_at  = humanize.time(created_at),
      description = custom_details
    }
    local message = mustache:render(telegram_message_firing_template, alert)
    local _, err  = telegram_bot:sendMessage({
      chat_id    = chat_id,
      text       = message,
      parse_mode = "html"
    })
    if err then error(err) end
    silence_to = time.unix() + 60 * 60
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
        plugin_log:printf("[ERROR] while process row: `%s` plugin '%s' on host '%s' error: %s\n", inspect(row), plugin:name(), plugin:host(), err)
      end
    end
  end
end

return process