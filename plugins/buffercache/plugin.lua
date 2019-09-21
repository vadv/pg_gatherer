local plugin               = 'pg.buffercache'
local every                = 300

local current_dir          = filepath.join(root, "buffercache")
local sql_buffercache, err = ioutil.read_file(filepath.join(current_dir, "buffercache.sql"))
if err then error(err) end

local snapshot = nil

local function collect_for_db(conn)
  local result            = conn:query(sql_buffercache, every)
  local per_relation_stat = {}
  --[===[
    convert from:
      {"full_relation_name" = "x", buffers = 1, usage_count = 3, dirty = true},
      {"full_relation_name" = "x", buffers = 1, usage_count = 3, dirty = false},
      {"full_relation_name" = "x", buffers = 1, usage_count = 5, dirty = false},
      {"full_relation_name" = "x", buffers = 2, usage_count = 2, dirty = false},
    to:
      {"full_relation_name" = "x", buffers = 5, usage_count_3 = 3, usage_count_0 = 0, dirty_count = 1}
  --]===]
  local database_state    = {
    datname       = nil,
    buffers_count = 0,
    dirty_count   = 0,
    usage_count_0 = 0,
    usage_count_3 = 3,
  }
  for _, row in pairs(result.rows) do

    if not snapshot then snapshot = row[1] end

    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    database_state.datname       = database_state.datname or jsonb.current_database
    local relation               = jsonb.full_relation_name
    local buffers                = tonumber(jsonb.buffers) or 0
    local usage_count            = tonumber(jsonb.usagecount) or 0
    local is_dirty               = jsonb.dirty

    -- calc database_state
    database_state.buffers_count = database_state.buffers_count + buffers
    if is_dirty then
      database_state.dirty_count = database_state.dirty_count + buffers
    end
    if usage_count == 0 then
      database_state.usage_count_0 = database_state.usage_count_0 + buffers
    end
    if usage_count >= 3 then
      database_state.usage_count_3 = database_state.usage_count_3 + buffers
    end

    if relation then
      if per_relation_stat[relation] == nil then
        per_relation_stat[relation] = {
          full_relation_name = relation,
          buffers            = 0,
          dirty_count        = 0,
          usage_count_0      = 0,
          usage_count_3      = 3,
        }
      end
      per_relation_stat[relation].buffers = per_relation_stat[relation].buffers + buffers
      if is_dirty then
        per_relation_stat[relation].dirty_count = per_relation_stat[relation].dirty_count + buffers
      end
      if usage_count == 0 then
        per_relation_stat[relation].usage_count_0 = per_relation_stat[relation].usage_count_0 + buffers
      end
      if usage_count >= 3 then
        per_relation_stat[relation].usage_count_3 = per_relation_stat[relation].usage_count_3 + buffers
      end
    end
  end
  local jsonb             = database_state
  jsonb.per_relation_stat = per_relation_stat
  local jsonb, err        = json.encode(jsonb)
  if err then error(err) end
  manager:send_metric({ plugin = plugin, snapshot = snapshot, json = jsonb })
end

local function collect()
  for _, conn in pairs(agent:available_agents()) do
    collect_for_db(conn)
  end
end

run_every(collect, every)
