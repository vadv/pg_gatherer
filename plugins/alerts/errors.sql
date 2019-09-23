with sum_errors as (
  select
    ts                                                          as ts,
    sum(coalesce((value_jsonb ->> 'xact_rollback')::float8, 0)) as rollback,
    sum(coalesce((value_jsonb ->> 'conflicts')::float8, 0))     as conflicts
  from
    metric
  where
      host = md5($1::text)::uuid
  and plugin = md5('pg.databases')::uuid
  and ts > ($2 - (10 * 60))
  and ts < $2
  group by ts
  order by ts desc
)
select
  percentile_cont(0.9) within group (order by rollback asc)  as rolback,
  percentile_cont(0.9) within group (order by conflicts asc) as conflicts
from
  sum_errors;