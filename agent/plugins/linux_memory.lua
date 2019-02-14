local plugin_base_name = 'linux_memory'

-- rds: no data
local function main_rds(agent, manager)
end
if is_rds then return main_rds end

local function main(agent, manager)
  for line in io.lines("/proc/meminfo") do
    local key, value = line:match("(%S+)%:%s+%d+%s+kB"), line:match("%S%:%s+(%d+)%s+kB")
    if key and value then
      insert_metric(host, plugin_base_name.."."..key, nil, tonumber(value*1024), nil, nil, manager)
    end
  end
end
return main
