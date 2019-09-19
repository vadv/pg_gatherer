local helpers = {}

-- /proc/<pid>/io
function helpers.read_linux_io_real(pid)
  local result   = {}
  local filename = string.format(HOST_PROC_DIR.."/%d/io", pid)
  local fh       = io.open(filename, "rb")
  if not fh then return result end
  local content = fh:read("*a");
  fh:close()
  for x in string.gmatch(content, "read_bytes: (%d+)\n") do result.read_bytes = tonumber(x) end
  for x in string.gmatch(content, "write_bytes: (%d+)\n") do result.write_bytes = tonumber(x) end
  for x in string.gmatch(content, "rchar: (%d+)\n") do result.rchar = tonumber(x) end
  for x in string.gmatch(content, "wchar: (%d+)\n") do result.wchar = tonumber(x) end
  for x in string.gmatch(content, "syscr: (%d+)\n") do result.syscr = tonumber(x) end
  for x in string.gmatch(content, "syscw: (%d+)\n") do result.syscw = tonumber(x) end
  return result
end

function helpers.read_linux_io(pid)
  local result = {}
  pcall(function() result = helpers.read_linux_io_real(pid) end)
  return result
end

-- /proc/<pid>/stat
function helpers.read_linux_cpu_real(pid)
  local result   = {}
  local filename = string.format(HOST_PROC_DIR.."/%d/stat", pid)
  local fh       = io.open(filename, "rb")
  if not fh then return result end
  local content = fh:read("*a");
  fh:close()
  -- 13 полей вместе с state: (R|S|...)
  -- state ppid pgrp session tty_nr tpgid  flags minflt cminflt majflt cmajflt utime stime
  for utime, stime in string.gmatch(content, " %a %d+ %d+ %d+ %d+ %-%d+ %d+ %d+ %d+ %d+ %d+ (%d+) (%d+)") do
    result.utime = tonumber(utime)
    result.stime = tonumber(stime)
  end
  return result
end

function helpers.read_linux_cpu(pid)
  local result = {}
  pcall(function() result = helpers.read_linux_cpu_real(pid) end)
  return result
end

helpers.calc_diff_t, helpers.count_calc_diff_call = {}, 0
function helpers.calc_diff(id, value)

  if not value then return nil end

  local now  = os.time()
  local prev = helpers.calc_diff_t[id]
  if (prev == nil) then
    helpers.calc_diff_t[id] = { touch = now, begin_value = value }
    return nil
  end

  -- обновляем доступ
  helpers.calc_diff_t[id]["touch"] = now

  -- если необходимо делаем компакт calc_diff_t
  helpers.count_calc_diff_call     = helpers.count_calc_diff_call + 1
  if (helpers.count_calc_diff_call % 100) == 0 then helpers.gc_calc_diff() end

  return value - prev["begin_value"]
end

function helpers.gc_calc_diff()
  local new_calc_diff_t = {}
  local garbage_time    = os.time() - (15 * 60)
  for id, val in pairs(helpers.calc_diff_t) do
    if val["touch"] > garbage_time then new_calc_diff_t[id] = val end
  end
  helpers.calc_diff_t = new_calc_diff_t
end

return helpers