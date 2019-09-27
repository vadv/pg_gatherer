local processors     = {}
processors.telegram  = dofile(filepath.join(plugin:dir(), "telegram.lua"))
processors.pagerduty = dofile(filepath.join(plugin:dir(), "pagerduty.lua"))

function process()
  for name, process_f in pairs(processors) do
    local status, err = pcall(process_f)
    if not status then
      plugin_log:printf("[ERROR] plugin '%s' processor '%s' error: %s\n", plugin:name(), name, err)
    end
  end
end

run_every(process, 5)