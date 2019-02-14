create schema if not exists manager;
create schema if not exists agent;

-- host
create table manager.host (
    name         text not null primary key,
    agent_token  text not null
);
create unique index host_token_idx on manager.host(agent_token);

-- metric data
create table manager.metric (
    id           bigserial,
    host         uuid not null,
    plugin       uuid not null,
    ts           timestamp not null default current_timestamp,
    snapshot     bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb
) partition by list(host);
