select
  value_jsonb ->> 'datname'                    as datname,
  coalesce((value_jsonb ->> 'age')::bigint, 0) as age
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.databases')::uuid
and ts > ($2 - 10 * 60)
and ts < $2
and coalesce((value_jsonb ->> 'age')::bigint, 0) > 300 * 1000 * 1000
order by
  2 desc
limit 1;