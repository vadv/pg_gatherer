if not goos.stat(HOST_PROC_DIR .. '/diskstats') then
  print('disabled plugin, because /proc/diskstats not found')
  return
end

if os.getenv('CI') then
  local dir = filepath.dir(debug.getinfo(1).source)
  local helper = dofile(filepath.join(dir, "helper_disk_stat.lua"))
  local count  = 0
  for dev, value in pairs(helper.read_diskstat()) do
    print("disk stat:", "dev:", dev, "value:", inspect(value))
    count = count + 1
  end
  if count == 0 then
    print('disabled plugin: diskstat is empty')
    return
  end
end

run_plugin_test(120, function() return metric_exists('linux.diskstats') end)
