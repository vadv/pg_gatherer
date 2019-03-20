create or replace function gatherer.pg_block() returns setof jsonb AS $$
    SELECT
    jsonb_build_object(
         'current_database', current_database(),
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
   FROM
        pg_catalog.pg_locks         blocked_locks
        JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
        JOIN pg_catalog.pg_locks         blocking_locks    ON blocking_locks.locktype = blocked_locks.locktype
            AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
            AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
            AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
            AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
            AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
            AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
            AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
            AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
            AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
            AND blocking_locks.pid != blocked_locks.pid
        JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
        WHERE NOT blocked_locks.GRANTED;
$$ language 'sql' security definer;
