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

local alert_key = "gatherer agent is not running"

local stmt, err = manager:stmt([[
  select
    max(ts),
    extract(epoch from current_timestamp)::bigint
  from
    manager.metric
  where
    host = md5($1::text)::uuid
    and plugin = md5('pg.healthcheck')::uuid
    and ts > ($2 - 10 * 60)
    and ts < $2
]])
if err then error(err) end

function collect()

  local current_unixts = unixts()

  for _, host in pairs(get_hosts()) do

    local result, err = stmt:query(host, current_unixts)
    if err then error(err) end
    local info = {}
    local jsonb, err = json.encode(info)
    if err then error(err) end
    if (result.rows[1] == nil) or (result.rows[1][1] == nil)
      or math.abs(result.rows[1][2] - result.rows[1][1]) > 5*60 then
      create_alert(host, alert_key, 'critical', jsonb)
    else
      resolve_alert(host, alert_key)
    end

  end
end

helpers.runner.run_every(collect, 60)
