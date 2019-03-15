create or replace function gatherer.pg_stat_activity(t int default 1) returns setof jsonb AS $$
    select
        jsonb_build_object(
          'sql_id', md5(query)::UUID,
          'query_id', md5(query || query_start::text)::UUID,
          'datname', datname::text,
          'pid', pid,
          'username', usename,
          'application_name', application_name,
          'client_addr', client_addr,
          'client_hostname', client_hostname,
          'client_port', client_port,
          'xact_start_duration', extract(epoch from now() - xact_start)::int,
          'query_start_duration', extract(epoch from now() - query_start)::int,
          'state_change_duration', extract(epoch from now() - state_change)::int,
          'wait_event_type', wait_event_type::text,
          'wait_event', wait_event::text,
          'state', state,
          'query', query::text
        ) as result
    from
      pg_catalog.pg_stat_activity
    where
        state <> 'idle' and query is not null and extract(epoch from now() - state_change)::int > t;
$$ language 'sql' security definer;

create or replace function gatherer.pg_stat_activity_waits() returns setof jsonb AS $$
    select
      jsonb_build_object(
        'state', a.state::text,
        'wait_event', a.wait_event::text,
        'wait_event_type', a.wait_event_type::text,
        'count', count(a.pid)::bigint
      )  as result
    from
      pg_catalog.pg_stat_activity a
    where
        state <> 'idle' and a.wait_event is not null
    group by a.wait_event, a.wait_event_type, a.state
$$ language 'sql' security definer;

create or replace function gatherer.pg_stat_activity_states(out state text, out count bigint) returns setof record AS $$
with states as (
  select * from unnest('{active,idle,idle in transaction,idle in transaction (aborted),fastpath function call}'::text[]) as state
)
    select
        s.state,
        count(a.pid) as count
    from
      states s
      left join pg_catalog.pg_stat_activity a on s.state = a.state
    group by s.state;
$$ language 'sql' security definer;
