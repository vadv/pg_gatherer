local json = require('json')
local inspect = require('inspect')
local plugin = 'pg.activity'

-- sql queries only
local function main_rds(agent, manager)

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_activity(1)")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    insert_metric(host, plugin, row[1], nil, nil, row[2], manager)
  end

  local result, err = agent:query("select state, count from gatherer.pg_stat_activity_states()")
  if err then error(err) end
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  insert_metric(host, plugin..".states", nil, nil, nil, jsonb, manager)
end
if is_rds then return main_rds end

-- with io/cpu statistics
local function main(agent, manager)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_activity(1)")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local pid = tonumber(jsonb.pid)
    if pid then
      -- IO for query
      local pid_io = linux_pid_stat.read_linux_io(pid)
      local rchar, wchar  = pid_io.rchar, pid_io.wchar
      if rchar and wchar then
        -- need root rights
        jsonb.rchar = linux_pid_stat.calc_diff("rchar-"..tostring(pid), rchar)
        jsonb.wchar = linux_pid_stat.calc_diff("wchar-"..tostring(pid), wchar)
      end
      -- CPU for query
      local pid_cpu = linux_pid_stat.read_linux_cpu(pid)
      local utime, stime  = pid_cpu.utime, pid_cpu.stime
      if utime or stime then
        -- need root rights for stime
        jsonb.utime = linux_pid_stat.calc_diff("utime-"..tostring(pid), utime)
        jsonb.stime = linux_pid_stat.calc_diff("stime-"..tostring(pid), stime)
      end
    end
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    insert_metric(host, plugin, row[1], nil, nil, jsonb, manager)
  end

  local result, err = agent:query("select state, count from gatherer.pg_stat_activity_states()")
  if err then error(err) end
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  insert_metric(host, plugin..".states", nil, nil, nil, jsonb, manager)
end
return main
