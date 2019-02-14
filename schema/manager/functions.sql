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
    values (md5($1)::uuid, $2, $3, $4, $5, $6)
$$ language 'sql' security definer;
