local json = require('json')
local plugin = 'linux.memory'

-- rds: no data
local function main_rds(agent, manager) end
if is_rds then return main_rds end

local function main(agent, manager)
  local jsonb = {}
  for line in io.lines("/proc/meminfo") do
    local key, value = line:match("(%S+)%:%s+%d+%s+kB"), line:match("%S%:%s+(%d+)%s+kB")
    if key and value then
      jsonb[key] = tonumber(value*1024)
    end
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  insert_metric(host, plugin, nil, nil, nil, jsonb, manager)
end
return main
