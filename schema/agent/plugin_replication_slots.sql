drop function if exists gatherer.pg_replication_slots;
create function gatherer.pg_replication_slots(out slot_name text, out size bigint) returns setof record AS $$
declare
    pg_version_num integer;
    pg_is_in_recovery boolean;
begin

    select current_setting('server_version_num') into pg_version_num;
    select pg_catalog.pg_is_in_recovery() into pg_is_in_recovery;

    if not pg_is_in_recovery then

        if pg_version_num >= 100000 then
            return query
                select
                    s.slot_name::text as slot_name,
                    pg_catalog.pg_wal_lsn_diff(pg_catalog.pg_current_wal_lsn(), s.confirmed_flush_lsn)::bigint as size
                from
                    pg_catalog.pg_replication_slots s;

        else
            return query
                select
                    s.slot_name::text as slot_name,
                    pg_catalog.pg_xlog_location_diff(pg_catalog.pg_current_xlog_location(), s.confirmed_flush_lsn)::bigint as size
                from
                    pg_catalog.pg_replication_slots s;
        end if;

    end if;

end
$$ language 'plpgsql' security definer;
