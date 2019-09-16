local plugin_name = 'pg.activity'

local sql_activity, err = ioutil.read_file(filepath.join(ROOT, "activity", "activity.lua"))
if err then error(err) end

for _, row in pairs(connection:query(sql_activity)) do
  manager:send_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
end