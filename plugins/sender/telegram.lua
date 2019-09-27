local token   = secrets:get("telegram_token")
local chat_id = secrets:get("telegram_chat_id")
if chat_id then chat_id = tonumber(chat_id) end

if not (token) or not (chat_id) then
  return function() end
end

plugin_log:printf("[INFO] start telegram sender\n")

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

function process_alert_row(alert)
  local cache_key                  = alert.key .. alert.host .. "telegram"
  local silence_to                 = cache:get(cache_key) or 0
  -- send message
  if time.unix() > silence_to then
    alert.created_at    = alert.created_at or alert.ts
    local alert   = {
      host        = alert.host,
      key         = alert.key,
      created_at  = humanize.time(alert.created_at),
      description = alert.custom_details
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

return process_alert_row
