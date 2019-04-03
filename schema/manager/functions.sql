create or replace function agent.create_parititons_for_host(host text, year int) returns void AS $$
declare
    min_month_counter int;
    main_table_name text;
    year_date date;
    interval_begin interval;
    interval_end interval;
    month_name text;
    begin_at int;
    end_at int;
    partition_table_name text;
    partition_index_name text;
begin
    main_table_name := (select (md5(host))::text);
    main_table_name := 'manager.metric_' || main_table_name;
    year_date := ( select to_date( year ||'-1-1', 'YYYY-MM-DD') );

    min_month_counter := 0;
    if year = (select extract(year from now())::int) then
        min_month_counter := (select extract(month from now())::int);
    end if;

    for month_counter IN min_month_counter..12 loop
        month_name := (select lpad(month_counter::text, 2, '0') );
        partition_table_name := main_table_name || '_' || year || '_' || month_name;
        partition_index_name := 'metric_' || md5(host)::text || '_' || year || '_' || month_name || '_idx' ;
        interval_begin := ( select (month_counter - 1 || ' month')::interval  );
        interval_end := ( select (month_counter || ' month')::interval - interval '1 second'  );
        begin_at := (select extract(epoch from date_trunc('year', year_date) + interval_begin ));
        end_at   := (select extract(epoch from date_trunc('year', year_date) + interval_end   ));
        execute 'create table if not exists ' || partition_table_name || ' partition of ' || main_table_name || ' for values from ('||  begin_at ||') to (' || end_at || ')';
        execute 'create index if not exists ' || partition_index_name || ' on ' || partition_table_name || ' (plugin, ts desc)';
    end loop;

end
$$ language 'plpgsql' security definer;

-- get agent connection and build partition tables if needed
create or replace function agent.get_agent_connection(token text) returns text AS $$
declare
    host text;
    table_name text;
    host_id text;
    result text;
begin
    result := (select agent_connection from manager.host where agent_token = $1 limit 1);
    host := (select name from manager.host where agent_token = $1 limit 1);
    if host is not null then
        host_id := quote_literal(md5(host));
        table_name := (select (md5(host))::text);
        table_name := 'manager.metric_' || table_name;
        execute 'create table if not exists ' || table_name  || ' partition of manager.metric for values in (' || host_id || ') partition by range(ts)';
        -- only current year
        perform agent.create_parititons_for_host(host, extract(year from now())::int);
    end if;
    return result;
end
$$ language 'plpgsql' security definer;

-- connection list
create or replace function agent.get_additional_agent_connections(token text) returns setof text AS $$
    select unnest(additional_agent_connections) from manager.host where agent_token = $1;
$$ language 'sql' security definer;

-- insert data
create or replace function agent.insert_metric(
    token text,
    plugin text,
    snapshot bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb) returns void AS $$
insert into manager.metric(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
    select
        md5(h.name)::uuid, md5($2)::uuid, $3, $4, $5, $6
    from
        manager.host h
    where
        h.agent_token = $1;
$$ language 'sql' security definer;

-- create alert if needed
create or replace function manager.create_alert_if_needed(
    hostname text,
    key text,
    severity manager.severity,
    info jsonb) returns void AS $$
begin

    -- create alert
    insert into manager.alert(host, key, severity)
        select $1, $2, least(p.max, $3)
            from manager.host h
                left join manager.severity_policy p on h.severity_policy_id = p.id
                where
                    h.name = $1
                    and not exists (select 1 from manager.alert a where a.host = $1 and a.key = $2 );

    -- update info
    update manager.alert set info = $4
        where id in
            ( select id from manager.alert a
                where
                    a.host = $1 and a.key = $2
                    and md5(coalesce(a.info::text, ' ')) <> md5(coalesce($4::text, ' '))
            );

end
$$ language 'plpgsql' security definer;

-- resolve alert
create or replace function manager.resolve_alert(
    hostname text,
    key text) returns void AS $$
declare
    info jsonb;
    created_at bigint;
    severity manager.severity;
begin
    created_at := (select a.created_at from manager.alert a where a.host = $1 and a.key = $2 limit 1);
    severity := (select a.severity from manager.alert a where a.host = $1 and a.key = $2 limit 1);
    if created_at is not null then
        info := (select a.info from manager.alert a where a.host = $1 and a.key = $2 limit 1);
        delete from manager.alert a where a.host = host and a.key = $2;
        insert into manager.alert_history (host, key, severity, created_at, ended_at, info)
            values ($1, $2, severity, created_at, extract(epoch from current_timestamp)::bigint, info);
    end if;
end
$$ language 'plpgsql' security definer;
