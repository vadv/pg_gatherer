drop function if exists gatherer.uptime;
create function gatherer.uptime() returns bigint AS $$
    select
        extract( epoch from (current_timestamp - pg_catalog.pg_postmaster_start_time()) )::bigint
$$ language 'sql' security definer;
