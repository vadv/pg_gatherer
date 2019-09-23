with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
      host = md5($1::text)::uuid
  and plugin = md5('pg.user_tables')::uuid
  and ts > ($2 - 10 * 60)
  and ts < $2
)
select
  value_jsonb ->> 'full_table_name' as full_table_name,
  round(
        100 * coalesce((value_jsonb ->> 'n_dead_tup')::float8, 0) / (
          coalesce((value_jsonb ->> 'n_live_tup')::float8, 0)
          + coalesce((value_jsonb ->> 'n_dead_tup')::float8, 0)
        )
    )                               as bloat
from
  data
where
    coalesce((value_jsonb ->> 'n_dead_tup')::bigint, 0) > 0
and (coalesce((value_jsonb ->> 'relpages')::bigint, 0) * 8 * 1024) > (256 * 1024 * 1024)
and round(
          100 * coalesce((value_jsonb ->> 'n_dead_tup')::float8, 0) / (
            coalesce((value_jsonb ->> 'n_live_tup')::float8, 0)
            + coalesce((value_jsonb ->> 'n_dead_tup')::float8, 0)
          )
      ) > 10
order by
  2 desc
limit 1;