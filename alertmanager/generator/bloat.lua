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
local function unixts()
  return helpers.query.unixts(helpers.connections.manager)
end

local alert_key = "table bloat is too big"

local stmt, err = manager:stmt([[
  with data as (
    select
        snapshot,
        jsonb_array_elements(value_jsonb) as value_jsonb
    from manager.metric where
      host = md5($1::text)::uuid
      and plugin = md5('pg.user_tables')::uuid
      and ts > ($2 - 10 * 60)
      and ts < $2
)
  select
    value_jsonb->>'full_table_name' as "full_table_name",
    round(
      100*coalesce((value_jsonb->>'n_dead_tup')::float8, 0) / (
          coalesce((value_jsonb->>'n_live_tup')::float8, 0)
          + coalesce((value_jsonb->>'n_dead_tup')::float8, 0)
        )
    ) as "bloat"
  from
    data
  where
    and coalesce((value_jsonb->>'n_dead_tup')::bigint, 0) > 0
    and (coalesce((value_jsonb->>'relpages')::bigint, 0) * 8 * 1024) > (256*1024*1024)
    and round(
      100*coalesce((value_jsonb->>'n_dead_tup')::float8, 0) / (
          coalesce((value_jsonb->>'n_live_tup')::float8, 0)
          + coalesce((value_jsonb->>'n_dead_tup')::float8, 0)
        )
    ) > 10
  order by 2 desc
  limit 1
]])

if err then error(err) end

function collect()

  local current_unixts = unixts()

  for _, host in pairs(get_hosts()) do

    local result, err = stmt:query(host, current_unixts)
    if err then error(err) end

    if not(result.rows[1] == nil) and not(result.rows[1][1] == nil) then
      local table_name, bloat = result.rows[1][1], result.rows[1][2]
      -- alert
      local jsonb = {custom_details={table_name=table_name, bloat=bloat}}
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      create_alert(host, alert_key, 'critical', jsonb)
    else
      resolve_alert(host, alert_key)
    end

  end
end

helpers.runner.run_every(collect, 60)
