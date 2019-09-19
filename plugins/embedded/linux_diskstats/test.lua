if not goos.stat(HOST_PROC_DIR..'/diskstats') then
  print('disabled plugin, because /proc/diskstats not found')
  return
end

run_plugin_test(120, function() return metric_exists('linux.diskstats') end)