local yaml = require("yaml")
local ioutil = require("ioutil")
local filepath = require("filepath")
local inspect = require("inspect")

-- read config file and ovveride from env variables
local function read_config_from_file(filename)
  local config = {}
  if not filename then return config end
  local data, err = ioutil.read_file(filename)
  if err then error(err) end
  config, err = yaml.decode(data)
  if err then error(err) end
  config.filename = filename
  return config
end

-- helpers for override config from env
local function override_config_from_env(config)

  -- cache
  config.cache_path = os.getenv("CACHE_PATH") or config.cache_path or '/var/tmp/pg_gatherer.cache'

  -- senders
  config.senders = config.senders or {}
  config.senders.telegram = config.senders.telegram or {}
  config.senders.telegram.token = os.getenv("TELEGRAM_TOKEN") or config.senders.telegram.token
  config.senders.telegram.chat = os.getenv("TELEGRAM_CHAT") or config.senders.telegram.chat
  config.senders.telegram.enabled = not (os.getenv("TELEGRAM_TOKEN") == nil)

  config.senders.pagerduty = config.senders.pagerduty or {}
  config.senders.pagerduty.rk = config.senders.pagerduty.rk or {}
  config.senders.pagerduty.token = os.getenv("PAGERDUTY_TOKEN") or config.senders.pagerduty.token
  config.senders.pagerduty.rk.default = os.getenv("PAGERDUTY_RK_DEFAULT") or config.senders.pagerduty.rk.default
  config.senders.pagerduty.rk.critical = os.getenv("PAGERDUTY_RK_CTITICAL") or config.senders.pagerduty.rk.critical or config.senders.pagerduty.rk.default
  config.senders.pagerduty.rk.error = os.getenv("PAGERDUTY_RK_ERROR") or config.senders.pagerduty.rk.error or config.senders.pagerduty.rk.default
  config.senders.pagerduty.rk.warning = os.getenv("PAGERDUTY_RK_WARNING") or config.senders.pagerduty.rk.warning or config.senders.pagerduty.rk.default
  config.senders.pagerduty.rk.info = os.getenv("PAGERDUTY_RK_INFO") or config.senders.pagerduty.rk.info or config.senders.pagerduty.rk.default
  config.senders.pagerduty.enabled = not (os.getenv("PAGERDUTY_TOKEN") == nil)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  -- connections
  config.manager = os.getenv("MANAGER") or config.manager

end

-- helpers for set config to env
local function save_config_to_env(config)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  local current_dir = filepath.dir(debug.getinfo(1).source)
  os.setenv("CONFIG_INIT", filepath.join(current_dir, "..", "init.lua"))
  os.setenv("MANAGER", config.manager)
  if config.filename then os.setenv("CONFIG_FILENAME", config.filename) end
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
