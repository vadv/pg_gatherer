select
  coalesce((value_jsonb -> 'created_at')::bigint, 0) as created_at
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.alerts')::uuid
and value_jsonb ->> 'key' = $2
and ts > ($3 - (10 * 60))
and ts < $3
order by
  1 desc