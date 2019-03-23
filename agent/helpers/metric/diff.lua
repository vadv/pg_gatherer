local time = require("time")
local db = require("db")
local filepath = require("filepath")

local create_table_every_sec = 60*60
local gc_sqlite_after_save_count = 1000

local sqlite, err = db.open("sqlite3", filepath.join(os.getenv("CACHE_PATH"), "diff.sqlite3"), {shared = true})
if err then error(err) end

local _, err = sqlite:command("PRAGMA synchronous = 0;")
if err then error(err) end

local _, err = sqlite:command("PRAGMA journal_mode = OFF;")
if err then error(err) end

local created_tables = {
  -- table_name = {
--    save_stmt = ud,
--    get_stmt = ud,
--  }
}

local function table_name_ts()
  local now = time.unix()
  local table_ts = now - (now%(create_table_every_sec))
  return "diff_"..tostring(table_ts)
end

local function get_and_check_table()
  local table_name_ts = table_name_ts()
  if created_tables[table_name_ts] then return table_name_ts end
  local _, err = sqlite:exec("create table if not exists " .. table_name_ts .. " (key text primary key, value real, updated_at real);")
  if err then error(err) end

  local get_stmt, err = sqlite:stmt("select value, updated_at from " .. table_name_ts .. " where key = ?")
  if err then error(err) end
  local save_stmt, err = sqlite:stmt("insert into ".. table_name_ts .. " (key, value, updated_at) values (?, ?, ?) on conflict (key) do update set value=excluded.value, updated_at=excluded.updated_at")
  if err then error(err) end

  created_tables[table_name_ts] = {
    get_stmt = get_stmt,
    save_stmt= save_stmt
  }
  return table_name_ts
end

-- drop old tables
local counter = 0
local function gc()
  counter = counter + 1
  if counter > gc_sqlite_after_save_count then
    local table_name_ts = table_name_ts()
    for k, _ in pairs( created_tables ) do
      if not(k == table_name_ts) then
        print("sqlite: drop table "..k)
        local _, err = sqlite:exec("drop table if exists "..k..";")
        if err then error(err) end
        created_tables[k] = nil
      end
    end
    conter = 0
  end
end

-- save
local function save(key, value)
  local table_name = get_and_check_table()
  local save_stmt = created_tables[table_name].save_stmt
  save_stmt:exec(key, value, time.unix())
  if err then error(err) end
  gc()
end

-- value, updated_at, found
local function get(key)
  local table_name = get_and_check_table()
  local get_stmt = created_tables[table_name].get_stmt
  local result, err = get_stmt:query(key)
  if err then error(err) end
  if result.rows and result.rows[1] then
    return result.rows[1][1], result.rows[1][2], true
  end
  return nil, nil, false
end

local function diff(key, value)

  if not value then return nil end

  local now = time.unix()

  local prev, _, found = get(key)
  if not found then
    save(key, value)
    return
  end

  -- overflow
  if prev > value then
    save(key, value)
    return
  end

  save(key, value)

  return value - prev
end

return diff
