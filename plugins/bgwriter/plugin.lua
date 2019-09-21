local plugin_name       = 'pg.bgwriter'
local every             = 60

local current_dir       = filepath.join(root, "bgwriter")
local sql_bgwriter, err = ioutil.read_file(filepath.join(current_dir, "bgwriter.sql"))
if err then error(err) end

local function collect()
  local result = agent:query(sql_bgwriter, every)
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    jsonb.checkpoints_timed     = cache:diff_and_set("checkpoints_timed", jsonb.checkpoints_timed)
    jsonb.checkpoints_req       = cache:diff_and_set("checkpoints_req", jsonb.checkpoints_req)
    jsonb.checkpoint_write_time = cache:diff_and_set("checkpoint_write_time", jsonb.checkpoint_write_time)
    jsonb.checkpoint_sync_time  = cache:diff_and_set("checkpoint_sync_time", jsonb.checkpoint_sync_time)
    jsonb.maxwritten_clean      = cache:diff_and_set("maxwritten_clean", jsonb.maxwritten_clean)
    jsonb.buffers_backend_fsync = cache:diff_and_set("buffers_backend_fsync", jsonb.buffers_backend_fsync)
    jsonb.buffers_alloc         = cache:diff_and_set("buffers_alloc", jsonb.buffers_alloc)
    jsonb.buffers_checkpoint    = cache:speed_and_set("buffers_checkpoint", jsonb.buffers_checkpoint)
    jsonb.buffers_clean         = cache:speed_and_set("buffers_clean", jsonb.buffers_clean)
    jsonb.buffers_backend       = cache:speed_and_set("buffers_backend", jsonb.buffers_backend)
    jsonb, err                  = json.encode(jsonb)
    if err then error(err) end
    manager:send_metric({ plugin = plugin_name, snapshot = row[1], json = jsonb })
  end
end

run_every(collect, every)
