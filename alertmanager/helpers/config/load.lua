local goos = require("goos")
local yaml = require("yaml")
local ioutil = require("ioutil")
local filepath = require("filepath")
local inspect = require("inspect")

-- read config file and ovveride from env variables
local function read_config_from_file(filename)
  local config = {}
  if goos.stat(filename) then
    local data, err = ioutil.read_file(filename)
    if err then error(err) end
    config, err = yaml.decode(data)
    if err then error(err) end
  end
  config.filename = filename
  return config
end

-- helpers for override config from env
local function override_config_from_env(config)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  config = config or {}

  -- connections
  config.connections = config.connections or {}
  config.connections.manager = config.connections.manager or os.getenv("CONNECTION_MANAGER")

  -- cache
  config.cache_path = config.cache_path or os.getenv("CACHE_PATH") or '/var/tmp/pg_gatherer.cache'

  -- senders
  config.senders = config.senders or {}
  config.senders.telegram = config.senders.telegram or {}
  config.senders.telegram.enabled = config.senders.telegram.enabled or os.getenv("TELEGRAM_ENABLED")
  config.senders.telegram.token = config.senders.telegram.token or os.getenv("TELEGRAM_TOKEN")
  config.senders.telegram.chat = config.senders.telegram.chat or os.getenv("TELEGRAM_CHAT")

end

-- helpers for set config to env
local function save_config_to_env(config)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  local current_dir = filepath.dir(debug.getinfo(1).source)
  os.setenv("CONFIG_INIT", filepath.join(current_dir, "..", "init.lua"))
  os.setenv("CONNECTION_MANAGER", config.connections.manager)
  os.setenv("CONFIG_FILENAME", config.filename)
  os.setenv("CACHE_PATH", config.cache_path)
end

local function load(filename)
  local config = read_config_from_file(filename)
  override_config_from_env(config)
  save_config_to_env(config)
  os.setenv("CONFIG_INITILIZED", "TRUE")
  return config
end

return load
