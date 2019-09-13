local err = manager:metric({plugin="plugin.int", int=10})
if err then error(err) end

local result, err = connection:query("select value_bigint from metric where plugin = md5('plugin.int')::uuid ")
if err then error(err) end
if not(result.rows[1][1] == 10) then error("value must be 10, but get: "..tostring(result.rows[1][1])) end