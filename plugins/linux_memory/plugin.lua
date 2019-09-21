local plugin = 'linux.memory'
local every  = 60

local function collect()
  local jsonb = {}
  for line in io.lines(HOST_PROC_DIR .. "/meminfo") do
    local key, value = line:match("(%S+)%:%s+%d+%s+kB"), line:match("%S%:%s+(%d+)%s+kB")
    if key and value then
      jsonb[key] = tonumber(value*1024)
    end
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  manager:insert_metric({plugin=plugin, json=jsonb})
end

run_every(collect, every)
