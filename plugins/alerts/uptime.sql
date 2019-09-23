select
  min(value_bigint) as uptime
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.uptime.checkpointer')::uuid
and ts > ($2 - 20 * 60)
and ts < $2;