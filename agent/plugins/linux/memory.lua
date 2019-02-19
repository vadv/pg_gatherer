local json = require('json')
local time = require('time')
local plugin = 'linux.memory'

local helpers = dofile(os.getenv("CONFIG_INIT"))
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()
  local jsonb = {}
  for line in io.lines("/proc/meminfo") do
    local key, value = line:match("(%S+)%:%s+%d+%s+kB"), line:match("%S%:%s+(%d+)%s+kB")
    if key and value then
      jsonb[key] = tonumber(value*1024)
    end
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  metric_insert(plugin, nil, nil, nil, jsonb)
end

-- run collect
helpers.runner.run_every(collect, 10)
