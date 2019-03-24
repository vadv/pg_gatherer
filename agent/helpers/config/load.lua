local yaml = require("yaml")
local ioutil = require("ioutil")
local filepath = require("filepath")

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

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  config = config or {}
  config.token = os.getenv("TOKEN") or config.token
  config.manager = os.getenv("MANAGER") or config.manager
  config.cache_path = config.cache_path or os.getenv("CACHE_PATH") or "/var/tmp/gatherer"
end

-- helpers for set config to env
local function save_config_to_env(config)

  if os.getenv("CONFIG_INITILIZED") == "TRUE" then return end

  if (not os.getenv("MANAGER")) and (not config.manager) then
    error("please setup manager connection")
  end

  if (not os.getenv("CACHE_PATH")) and (not config.cache_path) then
    error("please setup cache_path")
  end

  local current_dir = filepath.dir(debug.getinfo(1).source)
  os.setenv("CONFIG_INIT", filepath.join(current_dir, "..", "init.lua"))
  os.setenv("TOKEN", config.token)
  os.setenv("MANAGER", config.manager)
  os.setenv("CACHE_PATH", config.cache_path)
  if config.filename then os.setenv("CONFIG_FILENAME", config.filename) end
end

local function load(filename)
  local config = read_config_from_file(filename)
  override_config_from_env(config)
  save_config_to_env(config)
  os.setenv("CONFIG_INITILIZED", "TRUE")
  return config
end

return load
