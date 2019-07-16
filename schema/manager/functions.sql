-- get agent connection and build partition tables if needed
create or replace function agent.get_agent_connection(token text) returns text AS $$
    select agent_connection from manager.host where agent_token = $1 limit 1;
$$ language 'sql' security definer;

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
