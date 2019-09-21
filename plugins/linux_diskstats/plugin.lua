local plugin_name = 'linux.diskstats'
local every       = 10

if not goos.stat(HOST_PROC_DIR .. '/diskstats') then
  print('disabled diskstats plugin, because /proc/diskstats not found')
  while true do
    time.sleep(1)
  end
end

local helper = dofile(filepath.join(plugin:dir(), "helper_disk_stat.lua"))

local function collect()

  local devices_info, all_stats = {}, {}
  for dev, values in pairs(helper.read_diskstat()) do
    local mountpoint = helper.get_mountpoint_by_dev(dev)
    if mountpoint then
      devices_info[dev]               = {}
      devices_info[dev]["mountpoint"] = mountpoint
      all_stats[dev]                  = {
        utilization = values.tot_ticks / 10,
        read_bytes  = values.rd_sec_or_wr_ios * 512, read_ops = values.rd_ios,
        write_bytes = values.wr_sec * 512, write_ops = values.wr_ios
      }
      helper.calc_value(dev, values)
    end
  end

  for dev, info in pairs(devices_info) do
    local mountpoint         = info["mountpoint"]
    local utilization, await = 0, nil
    if dev:match("^md") then
      local slaves_info      = helper.md_device_sizes(dev)
      local total_slave_size = 0;
      for _, size in pairs(slaves_info) do total_slave_size = total_slave_size + size end
      local raid_level = helper.md_level(dev)
      if raid_level then
        -- для raid{0,1} просчитываем utilization с весом
        -- вес высчитывается = (размер slave) / (сумму размера slave-устройств)
        if (raid_level == "raid0") or (raid_level == "raid1") then
          for slave, size in pairs(slaves_info) do
            local weight      = size / total_slave_size
            utilization       = utilization + (all_stats[slave]["utilization"] * weight)
            local slave_await = helper.calc_values[slave]["await"]
            if slave_await then
              if await == nil then await = 0 end
              await = await + (slave_await * weight)
            end
          end
        end
      end
    else
      utilization = all_stats[dev]["utilization"]
      await       = helper.calc_values[dev]["await"]
    end
    -- send calculated values
    local jsonb       = { mountpoint = mountpoint }
    jsonb.utilization = cache:speed_and_set(plugin_name .. "utilization" .. mountpoint, utilization)
    jsonb.await       = await
    for _, key in pairs({ 'read_bytes', 'write_bytes', 'read_ops', 'write_ops' }) do
      jsonb[key] = cache:speed_and_set(plugin_name .. key .. mountpoint, all_stats[dev][key])
    end
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ plugin = plugin_name, json = jsonb })
  end

end

run_every(collect, every)
