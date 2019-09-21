local plugin                 = 'pg.replication_slots'
local every                  = 60

local current_dir            = filepath.join(root, "replication_slots")

local replication_slots_file = filepath.join(current_dir, "replication_slots_9.sql")
if get_pg_server_version() >= 10 then replication_slots_file = filepath.join(current_dir, "replication_slots_10.sql") end
local sql_replication_slots, err = ioutil.read_file(replication_slots_file)
if err then error(err) end

local function collect()
  local result = agent:query(sql_replication_slots)
  local jsonb  = {}
  for _, row in pairs(result.rows) do
    jsonb[row[1]] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  manager:send_metric({ plugin = plugin, json = jsonb })
end

run_every(collect, every)
