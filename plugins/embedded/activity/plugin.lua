local plugin_name = 'pg.activity'

local current_dir = filepath.join(root, "embedded", "activity")
local sql_activity, err = ioutil.read_file(filepath.join(current_dir, "activity.sql"))
if err then error(err) end

local sql_states, err = ioutil.read_file(filepath.join(current_dir, "states.sql"))
if err then error(err) end

local sql_waits, err = ioutil.read_file(filepath.join(current_dir, "waits.sql"))
if err then error(err) end

local helpers = dofile( filepath.join(current_dir, "linux_helper_proc_stat.lua") )

-- process states
local function states()
  local result = connection:query(sql_states)
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  manager:send_metric({ plugin = plugin_name..".states", json = jsonb })
end

-- process waits
local function waits()
  for _, row in pairs(connection:query(sql_waits)) do
    manager:send_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
end

-- collect on rds
local function collect_rds()
  for _, row in pairs(connection:query(sql_activity)) do
    manager:send_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
  states()
  waits()
end

-- collect on localhost
local function collect_local()
  -- process activity
  local result = connection:query(sql_activity)
  for _, row in pairs(result) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local pid = tonumber(jsonb.pid)
    if pid then
      -- IO for query
      local pid_io = helpers.linux.pid_stat.read_linux_io(pid)
      local rchar, wchar  = pid_io.rchar, pid_io.wchar
      if rchar and wchar then
        -- need root rights
        jsonb.rchar = helpers.linux.pid_stat.calc_diff("rchar-"..tostring(pid), rchar)
        jsonb.wchar = helpers.linux.pid_stat.calc_diff("wchar-"..tostring(pid), wchar)
      end
      -- CPU for query
      local pid_cpu = helpers.linux.pid_stat.read_linux_cpu(pid)
      local utime, stime  = pid_cpu.utime, pid_cpu.stime
      if utime or stime then
        -- need root rights for stime
        jsonb.utime = helpers.linux.pid_stat.calc_diff("utime-"..tostring(pid), utime)
        jsonb.stime = helpers.linux.pid_stat.calc_diff("stime-"..tostring(pid), stime)
      end
    end
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    manager:send_metric({ plugin = plugin_name, snapshot = row[1], json = jsonb })
  end
  states()
  waits()
end

-- choose function to collect
local f = collect_local
if is_rds() then f = collect_rds end

run_every(f, 60)