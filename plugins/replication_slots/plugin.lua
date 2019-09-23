local plugin_name            = 'pg.replication_slots'
local every                  = 60

local replication_slots_file = "replication_slots_9.sql"
if get_pg_server_version() >= 10 then replication_slots_file = "replication_slots_10.sql" end
local sql_replication_slots = read_file_in_plugin_dir(replication_slots_file)

local function collect()
  local result = target:query(sql_replication_slots)
  local jsonb  = {}
  for _, row in pairs(result.rows) do
    jsonb[row[1]] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  storage_insert_metric({ plugin = plugin_name, json = jsonb })
end

run_every(collect, every)
