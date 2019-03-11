create schema if not exists manager;
create schema if not exists agent;

-- host
create table manager.host (
    name         text not null primary key,
    agent_token  text not null,
    maintenance  bool not null default false
);
create unique index host_token_idx on manager.host(agent_token);

-- metric data
create table manager.metric (
    id           bigserial primary key,
    host         uuid not null,
    plugin       uuid not null,
    ts           bigint not null default extract(epoch from current_timestamp)::bigint,
    snapshot     bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb
) partition by list(host);

-- alerts
create table manager.alert (
    id serial primary key,
    host text not null,
    created_at bigint not null default extract(epoch from current_timestamp)::bigint,
    key text not null,
    info jsonb
);
create unique index manager_alert_uniq_idx on manager.alert(host, key);

-- alerts history
create table manager.alert_history (
    id bigserial primary key,
    host text not null,
    key text not null,
    created_at bigint not null default extract(epoch from current_timestamp)::bigint,
    ended_at bigint not null,
    info jsonb
);
create unique index manager_alert_history_uniq_idx on manager.alert(host, key, created_at);
