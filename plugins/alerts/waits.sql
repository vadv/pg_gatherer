with sum_waits as (
  select
    ts                                                  as ts,
    sum(coalesce((value_jsonb ->> 'count')::bigint, 0)) as waits
  from
    metric
  where
      host = md5($1::text)::uuid
  and plugin = md5('pg.activity.waits')::uuid
  and ts > ($2 - (20 * 60))
  and ts < $2
  and value_jsonb ->> 'state' <> 'idle in transaction'
  group by ts
  order by ts desc
)
select
  percentile_cont(0.9) within group (order by waits asc)
from
  sum_waits;