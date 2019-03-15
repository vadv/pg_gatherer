local time = require("time")
local telegram = require("telegram")
local http = require("http")
local humanize = require("humanize")
local storage = require("storage")
local json = require("json")



local helpers = dofile(os.getenv("CONFIG_INIT"))
local config = helpers.config.load(os.getenv("CONFIG_FILENAME"))
local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end

if not(config.senders.telegram) or not(config.senders.telegram.enabled) then
  print("disable telegram sender")
  while true do
    -- disable telegram
    time.sleep(60)
  end
end

print("start telegram sender")

local cache, err = storage.open(config.cache_path)
if err then error(err) end

local client = http.client({})
local telegram_bot = telegram.bot(config.senders.telegram.token, client)
local telegram_chat = tonumber(config.senders.telegram.chat)

local stmt, err = manager:stmt("select key, severity, info, created_at from manager.alert where host = $1")
if err then error(err) end

local function severity_to_int(severity)
  if severity == 'critial' then
    return 5
  elseif severity == 'error' then
    return 4
  elseif severity == 'warning' then
    return 3
  elseif severity == 'info' then
    return 2
  end
  return 1
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

        local info = {}
        if row[3] then
          info, err = json.decode(row[3])
          if err then error(err) end
        end
        -- format message
        local message = [[
  *Host*:    `%s`
  *Problem*: `%s`
  *Created*: `%s`
  ]]
        message = string.format(message, host, row[1], humanize.time(row[4]))

        -- send message
        local _, err = telegram_bot:sendMessage({
          chat_id = telegram_chat,
          text = message,
          parse_mode = "Markdown"
        })
        if err then error(err) end

        -- set key
        local ttl = ( 10 - (severity_to_int(row[2]) or 9) ) * 60
        local err = cache:set(cache_key, 1, ttl)
        if err then error(err) end
      end
    end
  end
end

helpers.runner.run_every(collect, 10)
