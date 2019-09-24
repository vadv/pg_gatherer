select
  value_jsonb::text
from
  metric
where
    host = md5($1::text)::uuid
and plugin = md5('pg.activity')::uuid
and ts > ($2 - 10 * 60)
and ts < $2
and (value_jsonb ->> 'state_change_duration')::bigint > 20 * 60
and (value_jsonb ->> 'backend_type' <> 'autovacuum worker')
and not (value_jsonb ->> 'query' ~ '^autovacuum: VACUUM')
limit 1;