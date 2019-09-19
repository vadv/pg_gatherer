select
  extract(epoch from (now() - backend_start))::bigint
from
  pg_catalog.pg_stat_activity
where
  backend_type = 'checkpointer'
limit 1;