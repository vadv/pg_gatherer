local goos = require("goos")
local yaml = require("yaml")
local ioutil = require("ioutil")
local strings = require("strings")
local filepath = require("filepath")

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
  config.token = config.token or os.getenv("TOKEN")
  config.connections = config.connections or {}
  config.connections.agent = config.connections.agent or os.getenv("CONNECTION_AGENT")
  config.connections.manager = config.connections.manager or os.getenv("CONNECTION_MANAGER")
end

-- helpers for set config to env
local function save_config_to_env(config)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  local current_dir = filepath.dir(debug.getinfo(1).source)
  os.setenv("CONFIG_INIT", filepath.join(current_dir, "..", "init.lua"))
  os.setenv("TOKEN", config.token)
  os.setenv("CONNECTION_AGENT", config.connections.agent)
  os.setenv("CONNECTION_MANAGER", config.connections.manager)
  os.setenv("CONFIG_FILENAME", config.filename)
end

local function load(filename)
  local config = read_config_from_file(filename)
  override_config_from_env(config)
  save_config_to_env(config)
  os.setenv("CONFIG_INITILIZED", "TRUE")
  return config
end

return load
