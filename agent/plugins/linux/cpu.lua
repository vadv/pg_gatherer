local json = require('json')
local time = require('time')
local plugin = 'linux.cpu'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local manager = helpers.connections.manager
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

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

local function collect()
  for line in io.lines("/proc/stat") do

    -- all cpu
    local cpu_all_line = line:match("^cpu%s+(.*)")
    if cpu_all_line then
      local cpu_all_values = read_cpu_values(cpu_all_line)
      local jsonb = {}
      for key, value in pairs(cpu_all_values) do
        jsonb[key] = helpers.metric.speed(key, value)
      end
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      metric_insert(plugin, nil, nil, nil, jsonb)
    end

    -- running, blocked
    local processes = line:match("^procs_(.*)")
    if processes then
      local key, val = string.match(processes, "^(%S+)%s+(%d+)")
      metric_insert(plugin.."."..key, nil, tonumber(val), nil, nil)
    end

    -- context switching
    local ctxt = line:match("^ctxt (%d+)")
    if ctxt then
      local diff = helpers.metric.speed("ctxt", tonumber(ctxt))
      if diff then metric_insert(plugin..".ctxt", nil, nil, diff, nil) end
    end

    -- fork rate
    local processes = line:match("^processes (%d+)")
    if processes then
      local diff = helpers.metric.speed("processes", tonumber(processes))
      if diff then metric_insert(plugin..".fork_rate", nil, nil, diff, nil) end
    end

    -- interrupts
    local intr = line:match("^intr (%d+)")
    if intr then
      local diff = helpers.metric.speed("intr", tonumber(intr))
      if diff then metric_insert(plugin..".intr", nil, nil, diff, nil) end
    end

  end
end

-- run collector to infinity
while true do
  collect()
  time.sleep(10)
end
