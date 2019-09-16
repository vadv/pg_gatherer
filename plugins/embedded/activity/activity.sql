do
$plpgsql$
  declare
    pg_version_num integer;
  begin
    select current_setting('server_version_num') into pg_version_num;
    if pg_version_num >= 100000 then
      return query
        select
            extract(epoch from now())::int - (extract(epoch from now())::int % 60),
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
                'query', query::text,
                'backend_type', backend_type::text
              ) as result
        from
          pg_catalog.pg_stat_activity
        where
            state <> 'idle'
        and query is not null
        and backend_type not in ('walsender', 'checkpointer', 'walwriter')
        and extract(epoch from now() - state_change)::int > 30;
    else
      return query
        select
            extract(epoch from now())::int - (extract(epoch from now())::int % 60),
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
                'query', query::text
              ) as result
        from
          pg_catalog.pg_stat_activity
        where
            state <> 'idle'
        and query is not null
        and extract(epoch from now() - state_change)::int > 30;
    end if;
  end
$plpgsql$;