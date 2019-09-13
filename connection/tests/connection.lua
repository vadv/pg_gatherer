local inspect = require("inspect")

function check_ud(ud)
    local result, err = ud:query("select $1::integer, $1::text, $2", 1, "1")
    if err then error(err) end
    print(inspect( result  ))

    if not(result.rows[1][1] == 1) then error("helpers") end
    if not(result.rows[1][2] == "1") then error("helpers") end
end

-- check connection
check_ud(connection)

-- check available_connections
local connections, err = connection:available_connections()
if err then error(err) end
for _, v in pairs(connections) do
    check_ud(v)
end
