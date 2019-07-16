create schema if not exists manager;
create schema if not exists agent;

create type manager.severity as enum ('unknown', 'info', 'warning', 'error', 'critical');
create table manager.severity_policy (
    id  serial primary key,
    max manager.severity not null
);
insert into manager.severity_policy(max) values( 'warning'::manager.severity );

-- host
create table manager.host (
    name                         text   not null primary key,
    agent_token                  text   not null,
    agent_connection             text   not null,
    additional_agent_connections text[] not null,
    disabled                     bool not null default false,
    maintenance                  bool   not null default false,
    severity_policy_id           int    null references manager.severity_policy(id)
);
create unique index host_token_idx on manager.host(agent_token);

-- metric data
create table manager.metric (
    id           bigserial,
    host         uuid not null,
    plugin       uuid not null,
    ts           bigint not null default extract(epoch from current_timestamp)::bigint,
    snapshot     bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb
);
select create_hypertable('manager.metric', 'ts', chunk_time_interval => 86400000000);
create index ON manager.metric (ts, plugin, host);

-- alerts
create table manager.alert (
    id serial primary key,
    host text not null,
    created_at bigint not null default extract(epoch from current_timestamp)::bigint,
    key text not null,
    severity manager.severity not null default 'critical'::manager.severity,
    info jsonb
);
create unique index manager_alert_uniq_idx on manager.alert(host, key);

-- alerts history
create table manager.alert_history (
    id bigserial primary key,
    host text not null,
    key text not null,
    severity manager.severity not null,
    created_at bigint not null default extract(epoch from current_timestamp)::bigint,
    ended_at bigint not null,
    info jsonb
);
create unique index manager_alert_history_uniq_idx on manager.alert_history(host, key, created_at);
