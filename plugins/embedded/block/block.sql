select
  extract(epoch from now())::int - (extract(epoch from now())::int % $1),
  jsonb_build_object(
      'database', blocked_activity.datname,
      'blocked_query_id', md5(blocked_activity.query || blocked_activity.query_start::text)::UUID,
      'blocked_pid', blocked_locks.pid,
      'blocked_user', blocked_activity.usename,
      'blocked_duration', extract(epoch from now() - blocked_activity.query_start)::int,
      'blocking_query_id', md5(blocking_activity.query || blocking_activity.query_start::text)::UUID,
      'blocking_pid', blocking_locks.pid,
      'blocking_user', blocking_activity.usename,
      'blocking_duration', extract(epoch from now() - blocking_activity.query_start)::int,
      'blocked_statement', blocked_activity.query,
      'current_statement_in_blocking_process', blocking_activity.query,
      'blocked_application', blocked_activity.application_name,
      'blocking_application', blocking_activity.application_name
    ) as result
from
  pg_catalog.pg_locks blocked_locks
  join pg_catalog.pg_stat_activity blocked_activity on blocked_activity.pid = blocked_locks.pid
  join pg_catalog.pg_locks blocking_locks on blocking_locks.locktype = blocked_locks.locktype
    and blocking_locks.database is not distinct from blocked_locks.database
    and blocking_locks.relation is not distinct from blocked_locks.relation
    and blocking_locks.page is not distinct from blocked_locks.page
    and blocking_locks.tuple is not distinct from blocked_locks.tuple
    and blocking_locks.virtualxid is not distinct from blocked_locks.virtualxid
    and blocking_locks.transactionid is not distinct from blocked_locks.transactionid
    and blocking_locks.classid is not distinct from blocked_locks.classid
    and blocking_locks.objid is not distinct from blocked_locks.objid
    and blocking_locks.objsubid is not distinct from blocked_locks.objsubid
    and blocking_locks.pid != blocked_locks.pid
  join pg_catalog.pg_stat_activity blocking_activity on blocking_activity.pid = blocking_locks.pid
where
  not blocked_locks.granted;