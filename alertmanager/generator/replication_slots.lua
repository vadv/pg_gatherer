local json = require("json")
local inspect = require("inspect")
local helpers = dofile(os.getenv("CONFIG_INIT"))

local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end
local function create_alert(host, key, severity, info)
  helpers.query.create_alert(host, key, severity, info, helpers.connections.manager)
end
local function resolve_alert(host, key)
  helpers.query.resolve_alert(host, key, helpers.connections.manager)
end

local alert_key = "replication slots too big"

local stmt, err = manager:stmt([[
  select
    value_jsonb
  from
    manager.metric
  where
    host = md5($1::text)::uuid
    and plugin = md5('pg.replication_slots')::uuid
    and ts > (extract(epoch from current_timestamp)::bigint - 10 * 60)
  order by ts desc
  limit 1
]])

if err then error(err) end

function collect()
  for _, host in pairs(get_hosts()) do

    local result, err = stmt:query(host)
    if err then error(err) end

    if not(result.rows[1] == nil) and not(result.rows[1][1] == nil) then
      local info, err = json.decode(result.rows[1][1])
      if err then error(err) end

      -- calc max_size
      local max_size = 0
      for _, size in pairs(info) do
        if size > max_size then max_size = size end
      end

      local trigger_value = 1024 * 1024 * 1024
      if max_size > trigger_value then
        -- alert
        local jsonb = {custom_details=info}
        local jsonb, err = json.encode(jsonb)
        if err then error(err) end
        create_alert(host, alert_key, 'critical', jsonb)
      else
        resolve_alert(host, alert_key)
      end
    else
      resolve_alert(host, alert_key)
    end

  end
end

helpers.runner.run_every(collect, 5)
