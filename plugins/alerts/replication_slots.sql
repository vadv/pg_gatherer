select
  value_jsonb::text
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.replication_slots')::uuid
and ts > ($2 - 10 * 60)
and ts < $2
order by
  ts desc
limit 1;