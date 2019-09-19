if not goos.stat(HOST_PROC_DIR..'/stat') then
  print('disabled plugin, because /proc/stat not found')
  return
end

run_plugin_test(120, function() return metric_exists('linux.cpu') end)