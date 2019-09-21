local inspect = require("inspect")
local time = require("time")

function check_ud(ud)
    local result = ud:query("select $1::integer, $1::text, $2", 1, "1")
    print(inspect( result  ))

    if not(result.rows[1][1] == 1) then error("helpers") end
    if not(result.rows[1][2] == "1") then error("helpers") end
end

-- check connection
check_ud(connection)

-- check available_connections
local connections = connection:available_connections()
for _, v in pairs(connections) do
    check_ud(v)
end

local err = connection:insert_metric({plugin="plugin.int", int=10})
if err then error(err) end

local result, err = connection:query("select value_bigint from metric where plugin = md5('plugin.int')::uuid ")
if err then error(err) end
if not(result.rows[1][1] == 10) then error("value must be 10, but get: "..tostring(result.rows[1][1])) end

-- background query
local bg_query = connection:background_query("select pg_sleep($1), 1", 10)
time.sleep(1)
if not(bg_query:is_running()) then
    error("must be running")
end
bg_query:cancel()
time.sleep(1)
if bg_query:is_running() then
    error("must be not running")
end

bg_query = connection:background_query("select pg_sleep($1), 1", 2)
time.sleep(1)
if not(bg_query:is_running()) then
    error("must be running")
end
time.sleep(2)
if bg_query:is_running() then
    error("must be not running")
end
local result = bg_query:result()
if not(result.rows[1][2] == 1) then
    error("result: "..inspect(result))
end