local plugin_name   = 'pg.activity'
local every         = 60

local activity_file = "activity_9.sql"
if get_pg_server_version() >= 10 then activity_file = "activity_10.sql" end

local sql_activity = read_file_in_plugin_dir(activity_file)
local sql_states   = read_file_in_plugin_dir("states.sql")
local sql_waits    = read_file_in_plugin_dir("waits.sql")

local helpers      = dofile(filepath.join(plugin:dir(), "linux_helper_proc_stat.lua"))

local states_gauge = prometheus_gauge({ name = "activity_states", labels = { "state" } })
local waits_gauge  = prometheus_gauge({ name   = "activity_waits",
                                        labels = { "state", "wait_event", "wait_event_type" } })

-- process states
local function states()
  local result   = target:query(sql_states, every)
  local jsonb    = {}
  local snapshot = nil
  for _, row in pairs(result.rows) do
    if not (snapshot) then snapshot = row[1] end
    jsonb[row[2]] = tonumber(row[3])
    states_gauge:set(row[3], { state = row[2] })
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  storage_insert_metric({ plugin = plugin_name .. ".states", snapshot = snapshot, json = jsonb })
end

-- process waits
local function waits()
  local result = target:query(sql_waits, every)
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    waits_gauge:set(jsonb.count,
        { state = jsonb.state, wait_event = jsonb.wait_event, wait_event_type = jsonb.wait_event_type })
    storage_insert_metric({ plugin = plugin_name .. ".waits", snapshot = row[1], json = row[2] })
  end
end

-- collect on rds
local function collect_rds()
  local result = target:query(sql_activity, every, 30)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
  states()
  waits()
end

-- collect on localhost
local function collect_local()
  -- process activity
  local result = target:query(sql_activity, every, 30)
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local pid = tonumber(jsonb.pid)
    if pid then
      -- IO for query
      local pid_io       = helpers.read_linux_io(pid)
      local rchar, wchar = pid_io.rchar, pid_io.wchar
      if rchar and wchar then
        -- need root rights
        jsonb.rchar = helpers.calc_diff("rchar-" .. tostring(pid), rchar)
        jsonb.wchar = helpers.calc_diff("wchar-" .. tostring(pid), wchar)
      end
      -- CPU for query
      local pid_cpu      = helpers.read_linux_cpu(pid)
      local utime, stime = pid_cpu.utime, pid_cpu.stime
      if utime or stime then
        -- need root rights for stime
        jsonb.utime = helpers.calc_diff("utime-" .. tostring(pid), utime)
        jsonb.stime = helpers.calc_diff("stime-" .. tostring(pid), stime)
      end
    end
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = jsonb })
  end
  states()
  waits()
end

-- choose function to collect
local f = collect_local
if is_rds() then f = collect_rds end

run_every(f, every)
