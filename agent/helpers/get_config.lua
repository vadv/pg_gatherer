local goos = require("goos")
local yaml = require("yaml")
local ioutil = require("ioutil")
local strings = require("strings")

-- read config file and ovveride from env variables
local function read_config_from_file(filename)
  local config = {}
  if goos.stat(filename) then
    local data, err = ioutil.read_file(filename)
    if err then error(err) end
    config, err = yaml.decode(data)
    if err then error(err) end
  end
  return config
end

-- helpers for override config from env
local function override_config_from_env(config)
  config = config or {}
  config.token = config.token or os.getenv("TOKEN")
  config.connections = config.connections or {}
  config.connections.agent = config.connections.agent or os.getenv("CONNECTION_AGENT")
  config.connections.manager = config.connections.manager or os.getenv("CONNECTION_MANAGER")
end

local function get_config(filename)
  local config = read_config_from_file(filename)
  override_config_from_env(config)
  return config
end

return get_config
