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
  helpers.query.unixts(helpers.connections.manager)
end

local alert_key = "too many waits events"

local stmt, err = manager:stmt([[
  with sum_waits as (
    select
      ts as ts,
      sum( coalesce( (value_jsonb->>'count')::bigint, 0) ) as waits
    from
      manager.metric
    where
      host = md5($1::text)::uuid
      and plugin = md5('pg.activity.waits')::uuid
      and ts > ( $2 - (10 * 60) )
      and ts < $2
      and value_jsonb->>'state' <> 'idle in transaction'
    group by ts
    order by ts desc
)
  select
    percentile_cont(0.9) within group (order by waits asc)
  from
    sum_waits
]])

if err then error(err) end

function collect()

  local current_unixts = unixts()

  for _, host in pairs(get_hosts()) do

    local result, err = stmt:query(host, current_unixts)
    if err then error(err) end

    if not(result.rows[1] == nil) and not(result.rows[1][1] == nil) then
      if result.rows[1][1] > 50 then
        local jsonb = {
          custom_details = {
            percentile_90 = result.rows[1][1]
          }
        }
        local info, err = json.encode(jsonb)
        if err then error(err) end
        create_alert(host, alert_key, 'critical', info)
      else
        resolve_alert(host, alert_key)
      end
    else
      resolve_alert(host, alert_key)
    end

  end
end

helpers.runner.run_every(collect, 60)
