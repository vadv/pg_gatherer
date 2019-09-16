select
    extract(epoch from now())::int - (extract(epoch from now())::int % 60),
    jsonb_build_object(
        'state', a.state::text,
        'wait_event', a.wait_event::text,
        'wait_event_type', a.wait_event_type::text,
        'count', count(a.pid)::bigint
      ) as result
from
  pg_catalog.pg_stat_activity a
where
    state <> 'idle'
and a.wait_event is not null
group by
  a.wait_event, a.wait_event_type, a.state;