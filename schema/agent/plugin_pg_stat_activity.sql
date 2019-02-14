create or replace function gatherer.pg_stat_activity(t int default 1) returns setof jsonb AS $$
    select
        jsonb_build_object(
          'sql_id', md5(query)::UUID,
          'query_id', md5(query || query_start::text)::UUID,
          'datname', datname::text,
          'pid', pid,
          'username', usename,
          'application_name', application_name,
          'client_addr', client_addr,
          'client_hostname', client_hostname,
          'client_port', client_port,
          'xact_start_duration', extract(epoch from now() - xact_start)::int,
          'query_start_duration', extract(epoch from now() - query_start)::int,
          'state_change_duration', extract(epoch from now() - state_change)::int,
          'wait_event_type', wait_event_type::text,
          'wait_event', wait_event::text,
          'state', state,
          'query', quote_ident(query)::text
        ) as result
    from
      pg_catalog.pg_stat_activity
    where
        state <> 'idle' and extract(epoch from now() - state_change)::int > t;
$$ language 'sql' security definer;
