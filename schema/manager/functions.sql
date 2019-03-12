create or replace function agent.create_parititons_for_host(host text, year int) returns void AS $$
declare
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
    main_table_name := 'manager.' || quote_ident('metric_' || host);
    year_date := ( select to_date( year ||'-1-1', 'YYYY-MM-DD') );

    for month_counter IN 1..12 loop
        month_name := (select lpad(month_counter::text, 2, '0') );
        partition_table_name := main_table_name || '_' || year || '_' || month_name;
        partition_index_name := quote_ident('metric_' || host) || '_' || year || '_' || month_name || '_idx' ;
        interval_begin := ( select (month_counter - 1 || ' month')::interval  );
        interval_end := ( select (month_counter || ' month')::interval - interval '1 second'  );
        begin_at := (select extract(epoch from date_trunc('year', year_date) + interval_begin ));
        end_at   := (select extract(epoch from date_trunc('year', year_date) + interval_end   ));
        execute 'create table if not exists ' || partition_table_name || ' partition of ' || main_table_name || ' for values from ('||  begin_at ||') to (' || end_at || ')';
        execute 'create index if not exists ' || partition_index_name || ' on ' || partition_table_name || ' (plugin, ts desc)';
    end loop;

end
$$ language 'plpgsql' security definer;

-- check token for client
create or replace function agent.get_host(token text) returns text AS $$
declare
    host text;
    table_name text;
    host_id text;
begin
    host := (select name from manager.host where agent_token = token limit 1);
    if host is not null then
        host_id := quote_literal(md5(host));
        table_name := 'manager.' || quote_ident('metric_' || host);
        execute 'create table if not exists ' || table_name  || ' partition of manager.metric for values in (' || host_id || ') partition by range(ts)';
        -- only current year
        perform agent.create_parititons_for_host(host, extract(year from now())::int);
    end if;
    return host;
end
$$ language 'plpgsql' security definer;

-- insert data
create or replace function agent.insert_metric(
    host text,
    plugin text,
    snapshot bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb) returns void AS $$
insert into manager.metric(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
    values (md5($1)::uuid, md5($2)::uuid, $3, $4, $5, $6)
$$ language 'sql' security definer;

-- create alert if needed
create or replace function manager.create_alert_if_needed(
    host text,
    key text,
    info jsonb) returns void AS $$
    insert into manager.alert(host, key, info)
        select $1, $2, $3
        where
            not exists (select 1 from manager.alert where host = $1 and key = $2 );
    update manager.alert set info = $3
        where id in
            ( select id from manager.alert a
                where
                    host = $1 and key = $2
                    and md5(coalesce(a.info::text, ' ')) <> md5(coalesce($3::text, ' '))
            );
$$ language 'sql' security definer;

-- resolve alert
create or replace function manager.resolve_alert(
    host text,
    key text) returns void AS $$
declare
    info jsonb;
    created_at bigint;
begin
    created_at := (select a.created_at from manager.alert a where a.host = $1 and a.key = $2 limit 1);
    if created_at is not null then
        info := (select a.info from manager.alert a where a.host = $1 and a.key = $2 limit 1);
        delete from manager.alert a where a.host = $1 and a.key = $2;
        insert into manager.alert_history (host, key, created_at, ended_at, info)
            values ($1, $2, created_at, extract(epoch from current_timestamp)::bigint, info);
    end if;
end
$$ language 'plpgsql' security definer;
