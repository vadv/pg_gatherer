local json = require('json')
local plugin = 'linux.cpu'

-- rds: no data
local function main_rds(agent, manager) end
if is_rds then return main_rds end

-- read line from /proc/stat
local function read_cpu_values(str)
  -- https://www.kernel.org/doc/Documentation/filesystems/proc.txt
  local fields = { "user", "nice", "system", "idle", "iowait", "irq", "softirq", "steal", "guest", "guest_nice" }
  local row, offset = {}, 1
  for value in str:gmatch("(%d+)") do
    row[fields[offset]] = tonumber(value)
    offset = offset + 1
  end
  return row
end

local function main(agent, manager)
  for line in io.lines("/proc/stat") do

    -- all cpu
    local cpu_all_line = line:match("^cpu%s+(.*)")
    if cpu_all_line then
      local cpu_all_values = read_cpu_values(cpu_all_line)
      local jsonb = {}
      for key, value in pairs(cpu_all_values) do
        jsonb[key] = counter_speed(key, value)
      end
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      insert_metric(host, plugin, nil, nil, nil, jsonb, manager)
    end

    -- running, blocked
    local processes = line:match("^procs_(.*)")
    if processes then
      local key, val = string.match(processes, "^(%S+)%s+(%d+)")
      insert_metric(host, plugin.."."..key, nil, tonumber(val), nil, nil, manager)
    end

    -- context switching
    local ctxt = line:match("^ctxt (%d+)")
    if ctxt then
      local diff = counter_speed("ctxt", tonumber(ctxt))
      if diff then insert_metric(host, plugin..".ctxt", nil, nil, diff, nil, manager) end
    end

    -- fork rate
    local processes = line:match("^processes (%d+)")
    if processes then
      local diff = counter_speed("processes", tonumber(processes))
      if diff then insert_metric(host, plugin..".fork_rate", nil, nil, diff, nil, manager) end
    end

    -- interrupts
    local intr = line:match("^intr (%d+)")
    if intr then
      local diff = counter_speed("intr", tonumber(intr))
      if diff then insert_metric(host, plugin..".intr", nil, nil, diff, nil, manager) end
    end

  end
end
return main
