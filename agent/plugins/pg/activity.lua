local json = require('json')
local plugin = 'pg.activity'


local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.agent()

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

-- sql queries only
local function collect_rds()
  local result, err = agent:query("select gatherer.snapshot_id(30), * from gatherer.pg_stat_activity(30)")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, row[1], nil, nil, row[2])
  end

  local result, err = agent:query("select state, count from gatherer.pg_stat_activity_states()")
  if err then error(err) end
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  metric_insert(plugin..".states", nil, nil, nil, jsonb)

  local result, err = agent:query("select gatherer.snapshot_id(30), * from gatherer.pg_stat_activity_waits()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin..".waits", row[1], nil, nil, row[2])
  end
end

-- with io/cpu statistics
local function collect_with_linux()
  local result, err = agent:query("select gatherer.snapshot_id(30), * from gatherer.pg_stat_activity(30)")
  if err then error(err) end
  for _, row in pairs(result.rows) do
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
    metric_insert(plugin, row[1], nil, nil, jsonb)
  end

  local result, err = agent:query("select state, count from gatherer.pg_stat_activity_states()")
  if err then error(err) end
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  metric_insert(plugin..".states", nil, nil, nil, jsonb)

  local result, err = agent:query("select gatherer.snapshot_id(30), * from gatherer.pg_stat_activity_waits()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin..".waits", row[1], nil, nil, row[2])
  end
end


local collect_func = collect_with_linux
if helpers.is_rds then collect_func = collect_rds end
-- run collect
helpers.runner.run_every(collect_func, 30)
