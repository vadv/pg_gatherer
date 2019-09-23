function alerts_metric_exists()
  local sql_query = string.format([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.alerts')::uuid
  and ts > extract( epoch from (now()-'3 minute'::interval) )
  and ts > (value_jsonb->'created_at')::bigint + 10
  ]])
  local result    = target:query(sql_query).rows[1]
  if result and result[1] then
    return result[1] > 0
  end
  return false
end

local timeout = 120
tested_plugin:create()
while timeout > 0 do
  if tested_plugin:error_count() > 0 then
    error(tested_plugin:last_error())
  end
  if alerts_metric_exists() then
    tested_plugin:remove()
    return
  end
  time.sleep(1)
  timeout = timeout - 1
end
error("execution timeout")