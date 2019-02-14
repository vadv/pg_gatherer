create schema if not exists gatherer;

create or replace function gatherer.snapshot_id(o int default 60) returns int AS $$
    select extract(epoch from now())::int - (extract(epoch from now())::int % o)
$$ language 'sql' immutable;

