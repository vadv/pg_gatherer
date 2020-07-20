with data as (
  select
    snapshot,
    value_jsonb
  from
    metric
  where
      host = md5($1::text)::uuid
  and plugin = md5('pg.sequences')::uuid
  and ts > ($2 - 10 * 60)
  and ts < $2
)
select (value_jsonb->'sequence_name')::text as full_sequence_name, (value_jsonb->'remaining_capacity')::text::float as remaining_capacity
from data
where (value_jsonb->'remaining_capacity')::text::float < 20.0
