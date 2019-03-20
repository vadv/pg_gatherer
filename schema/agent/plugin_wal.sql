drop function if exists gatherer.pg_wal_position;
create function gatherer.pg_wal_position(
    out wal_position bigint
    , out pg_is_in_recovery boolean
    , out time_lag float8
    ) returns setof record AS $$
declare
    pg_version_num integer;
    pg_is_in_recovery boolean;
begin
    select current_setting('server_version_num') into pg_version_num;
    select pg_is_in_recovery() into pg_is_in_recovery;
    if pg_version_num >= 100000 then
        if pg_is_in_recovery then
            return query select
                pg_wal_lsn_diff(pg_last_wal_replay_lsn(), '0/00000000')::bigint as wal_position,
                pg_is_in_recovery as pg_is_in_recovery,
                extract(epoch from now() - pg_last_xact_replay_timestamp())::float8 as time_lag;
        else
            return query select
                pg_wal_lsn_diff(pg_current_wal_lsn(), '0/00000000')::bigint as wal_position,
                pg_is_in_recovery as pg_is_in_recovery,
                0::float8 as time_lag;
        end if;
    else
        if pg_is_in_recovery then
            return query select
                pg_xlog_location_diff(pg_last_xlog_replay_location(), '0/00000000')::bigint as wal_position,
                pg_is_in_recovery as pg_is_in_recovery,
                extract(epoch from now() - pg_last_xact_replay_timestamp())::float8 as time_lag;
        else
            return query select
                pg_xlog_location_diff(pg_current_xlog_location(), '0/00000000')::bigint as wal_position,
                pg_is_in_recovery as pg_is_in_recovery,
                0::float8 as time_lag;
        end if;
    end if;
end
$$ language 'plpgsql' security definer;
