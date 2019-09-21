with states as (
  select *
  from
    unnest('{active,idle,idle in transaction,idle in transaction (aborted),fastpath function call}'::text[])
)
select
    extract(epoch from now())::int - (extract(epoch from now())::int % $1),
    s.unnest,
    count(a.pid) as count
from
  states s
  left join pg_catalog.pg_stat_activity a on s.unnest = a.state
group by
  s.unnest;