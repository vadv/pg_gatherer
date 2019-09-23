select
  max(ts),
  extract(epoch from current_timestamp)::bigint
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.healthcheck')::uuid
and ts > ($2 - 10 * 60)
and ts < $2;