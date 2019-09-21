select
  extract(epoch from now())::int - (extract(epoch from now())::int % $1),
  jsonb_build_object(
      'checkpoints_timed', checkpoints_timed,
      'checkpoints_req', checkpoints_req,
      'checkpoint_write_time', checkpoint_write_time,
      'checkpoint_sync_time', checkpoint_sync_time,
      'maxwritten_clean', maxwritten_clean,
      'buffers_backend_fsync', buffers_backend_fsync,
      'buffers_alloc', buffers_alloc,
      'buffers_checkpoint', buffers_checkpoint,
      'buffers_clean', buffers_clean,
      'buffers_backend', buffers_backend
    ) as result
from
  pg_catalog.pg_stat_bgwriter;