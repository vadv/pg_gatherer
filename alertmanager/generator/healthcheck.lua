local json = require("json")
local helpers = dofile(os.getenv("CONFIG_INIT"))

local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end
local function create_alert(host, key, info)
  helpers.query.create_alert(host, key, info, helpers.connections.manager)
end
local function resolve_alert(host, key)
  helpers.query.resolve_alert(host, key, helpers.connections.manager)
end

local alert_key = "gatherer agent is not running for host"

function collect()

  local stmt, err = manager:stmt("select max(ts) from manager.metric where host = md5($1::text)::uuid")
  if err then error(err) end

  for _, host in pairs(get_hosts()) do

    local result, err = stmt:query(host)
    if err then error(err) end

    local info = {}
    local jsonb, err = json.encode(info)
    if err then error(err) end
    if result.rows[1][1] > 1 then
      create_alert(host, alert_key, jsonb)
    else
      resolve_alert(host, alert_key)
    end

  end

  local err = stmt:close()
  if err then error(err) end

end

helpers.runner.run_every(collect, 2)
