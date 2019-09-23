local plugin_name = 'linux.cpu'
local every       = 60

-- read line from /proc/stat
local function read_cpu_values(str)
  -- https://www.kernel.org/doc/Documentation/filesystems/proc.txt
  local fields      = { "user", "nice", "system", "idle", "iowait", "irq", "softirq", "steal", "guest", "guest_nice" }
  local row, offset = {}, 1
  for value in str:gmatch("(%d+)") do
    row[fields[offset]] = tonumber(value)
    offset              = offset + 1
  end
  return row
end

local function collect()
  for line in io.lines(HOST_PROC_DIR .. "/stat") do

    -- all cpu
    local cpu_all_line = line:match("^cpu%s+(.*)")
    if cpu_all_line then
      local cpu_all_values = read_cpu_values(cpu_all_line)
      local jsonb          = {}
      for key, value in pairs(cpu_all_values) do
        jsonb[key] = cache:speed_and_set(key, value)
      end
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      storage_insert_metric({ plugin = plugin_name, json = jsonb })
    end

    -- running, blocked
    local processes = line:match("^procs_(.*)")
    if processes then
      local key, val = string.match(processes, "^(%S+)%s+(%d+)")
      storage_insert_metric({ plugin = plugin_name .. "." .. key, int = tonumber(val) })
    end

    -- context switching
    local ctxt = line:match("^ctxt (%d+)")
    if ctxt then
      local diff = cache:speed_and_set("ctxt", tonumber(ctxt))
      if diff then storage_insert_metric({ plugin = plugin_name .. ".ctxt", float = diff }) end
    end

    -- fork rate
    local processes = line:match("^processes (%d+)")
    if processes then
      local diff = cache:speed_and_set("processes", tonumber(processes))
      if diff then storage_insert_metric({ plugin = plugin_name .. ".fork_rate", float = diff }) end
    end

    -- interrupts
    local intr = line:match("^intr (%d+)")
    if intr then
      local diff = cache:speed_and_set("intr", tonumber(intr))
      if diff then storage_insert_metric({ plugin = plugin_name .. ".intr", float = diff }) end
    end

  end
end

run_every(collect, every)
