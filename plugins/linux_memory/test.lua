if not goos.stat(HOST_PROC_DIR..'/meminfo') then
  print('disabled plugin, because /proc/meminfo not found')
  return
end

run_plugin_test(120, function() return metric_exists('linux.memory') end)