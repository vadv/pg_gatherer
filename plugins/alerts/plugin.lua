plugin_name      = 'pg.alerts'
local every      = 60

-- list of files
local files, err = filepath.glob(filepath.join(plugin:dir(), "*.lua"))
if err then error(err) end

-- load checks
local checks = {}
for _, file in pairs(files) do
  if not(strings.has_suffix(file, "plugin.lua"))
      and not(strings.has_suffix(file, "test.lua")) then
    checks[file] = dofile(file)
  end
end

-- get last value
local last_created_at_sql = read_file_in_plugin_dir("last_created_at.sql")
function get_last_created_at(host, key, unix_ts)
  if storage:query(last_created_at_sql, host, key, unix_ts).rows[1] then
    return storage:query(last_created_at_sql, host, key, unix_ts).rows[1][1]
  end
  return unix_ts
end

-- collect function
function collect()
  local unix_ts = get_unix_ts(storage)
  local result  = storage:query("select name from host where not maintenance")
  for _, row in pairs(result.rows) do
    local host = row[1]
    for _, check in pairs(checks) do
      check(host, unix_ts)
    end
  end
end

run_every(collect, every)