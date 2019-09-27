with data as (
  select
    value_jsonb ->> 'key'  as key,
    value_jsonb ->> 'host' as host_text,
    host                   as host,
    max(ts)                as ts
  from
    metric
  where
      host = md5($1::text)::uuid
  and plugin = md5('pg.alerts')::uuid
  and ts > ($2 - 5 * 60)
  and ts < $2
  group by 1, 2, 3
)
select
  d.key,
  d.ts,
  d.host_text,
  m.value_jsonb ->> 'custom_details' as custom_details,
  (m.value_jsonb ->> 'created_at')::bigint as created_at
from
  data d
  inner join metric m on m.ts = d.ts and m.host = d.host
where
    m.host = md5($1::text)::uuid
and m.plugin = md5('pg.alerts')::uuid
and m.ts > ($2 - 5 * 60)
and m.ts < $2;