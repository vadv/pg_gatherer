local time = require("time")
local telegram = require("telegram")
local http = require("http")
local humanize = require("humanize")

local helpers = dofile(os.getenv("CONFIG_INIT"))
local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end

if not(os.getenv("TELEGRAM_ENABLED") == "true") then
  while true do
    -- disable telegram
    time.sleep(60)
  end
end

local client = http.client({})
local telegram_bot = telegram.bot(os.getenv("TELEGRAM_TOKEN"), client)
local telegram_chat = os.getenv("TELEGRAM_CHAT")

local cache = {
  -- host+key = { created_at = time, notify_at = time }
}
local cache_counter = 0
function cache.get(host, key)
  -- body
end

local stmt, err = manager:stmt("select key, info, created_at from manager.alert where host = $1")
if err then error(err) end

function collect()
  for _, host in pairs(get_hosts()) do
    local result, err = stmt:query(host)
    if err then error(err) end
    for _, row in pairs(result.rows) do

      -- format message
      local message = [[
Host:    %s
Problem: %s
Age:     %s
]]
      message = string.format(message, host, row[1], humanize.time(row[3]))

      -- send message
      local _, err = telegram_bot:sendMessage({
        chat_id = telegram_chat,
        text = message
      })
      if err then error(err) end

    end
  end
end

helpers.runner.run_every(collect, 10)
