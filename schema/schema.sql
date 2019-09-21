create table metric (
    id           bigserial,
    host         uuid not null,
    plugin       uuid not null,
    ts           bigint not null default extract(epoch from current_timestamp)::bigint,
    snapshot     bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb
);
select create_hypertable('metric', 'ts', chunk_time_interval => 43200); /* comment if you don't use timescaledb */
create index on metric (ts, plugin, host);

create table host (
  name text primary key,
  maintenance bool default false
);