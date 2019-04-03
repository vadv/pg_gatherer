drop function if exists gatherer.uptime;
create function gatherer.uptime() returns bigint AS $$
    select
        extract( epoch from (current_timestamp - pg_catalog.pg_postmaster_start_time()) )::bigint
$$ language 'sql' security definer;

drop function if exists gatherer.checkpointer_uptime;
create function gatherer.checkpointer_uptime() returns bigint AS $$
declare
    pg_version_num integer;
begin
    select current_setting('server_version_num') into pg_version_num;
    if pg_version_num >= 100000 then
        return
            extract( epoch from (now() - backend_start) )::bigint
        from
            pg_catalog.pg_stat_activity
        where
            backend_type = 'checkpointer'
        limit 1;
    end if;
end
$$ language 'plpgsql' security definer;
