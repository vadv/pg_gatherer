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

local alert_key = "checkpointer uptime is too small: check logs for crash"

local stmt, err = manager:stmt([[
  select
    min(value_bigint) as "uptime"
  from
    manager.metric
  where
    host = md5($1::text)::uuid
    and plugin = md5('pg.uptime.checkpointer')::uuid
    and ts > ($2 - 20 * 60)
    and ts < $2
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
      local uptime = result.rows[1][1]
      if uptime > 60 then
        resolve_alert(host, alert_key)
      else
        -- alert
        local jsonb = {custom_details={uptime=uptime}}
        local jsonb, err = json.encode(jsonb)
        if err then error(err) end
        create_alert(host, alert_key, 'critical', jsonb)
      end
    end

  end
end

helpers.runner.run_every(collect, 60)
