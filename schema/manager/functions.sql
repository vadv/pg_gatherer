-- check token for client
create or replace function agent.get_host(token text) returns text AS $$
declare
    host text;
    table_name text;
    index_name text;
    host_id text;
begin
    host := (select name from manager.host where agent_token = token limit 1);
    if host is not null then
        host_id := quote_literal(md5(host));
        table_name := 'manager.' || quote_ident('metric_' || host);
        index_name := quote_ident('idx_metric_' || host || '_ts_plugin');
        execute 'create table if not exists ' || table_name  || ' partition of manager.metric for values in (' || host_id || ')';
        execute 'create index if not exists ' || index_name  || ' on ' || table_name || ' (ts, plugin)';
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
