local time = require("time")
local telegram = require("telegram")
local http = require("http")
local humanize = require("humanize")
local storage = require("storage")

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

print("start telegram sender")

local cache, err = cache.open(os.getenv("CACHE_PATH"))
if err then error(err) end

local client = http.client({})
local telegram_bot = telegram.bot(os.getenv("TELEGRAM_TOKEN"), client)
local telegram_chat = tonumber(os.getenv("TELEGRAM_CHAT"))

local stmt, err = manager:stmt("select key, info, created_at from manager.alert where host = $1")
if err then error(err) end

function collect()
  for _, host in pairs(get_hosts()) do
    local result, err = stmt:query(host)
    if err then error(err) end
    for _, row in pairs(result.rows) do

      local cache_key = host .. row[1]
      local _, found, err = cache:get(cache_key)
      if err then error(err) end

      if not found then

        local info, err = json.decode(row[2])
        if err then error(err) end

        -- format message
        local message = [[
  *Host*:    `%s`
  *Problem*: `%s`
  *Created*: `%s`
  ]]
        message = string.format(message, host, row[1], humanize.time(row[3]))

        -- send message
        local _, err = telegram_bot:sendMessage({
          chat_id = telegram_chat,
          text = message,
          parse_mode = "Markdown"
        })
        if err then error(err) end

        -- set key
        local ttl = ( 10 - (info.priority or 0) ) * 60
        local err = cache:set(cache_key, ttl)
        if err then error(err) end
      end
    end
  end
end

helpers.runner.run_every(collect, 10)
