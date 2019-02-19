local time = require("time")
local plugin = 'pg.wal'

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_block()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    insert_metric(host, plugin, row[1], nil, nil, row[2], manager)
  end
end

while true do
  time.sleep(10)
end
