create schema if not exists gatherer;

drop function if exists gatherer.version;
create function gatherer.version() returns int AS $$
    select 1;
$$ language 'sql' immutable;

drop function if exists gatherer.snapshot_id;
create function gatherer.snapshot_id(o int default 60) returns int AS $$
    select extract(epoch from now())::int - (extract(epoch from now())::int % o)
$$ language 'sql' immutable;
