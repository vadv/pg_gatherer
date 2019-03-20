local json = require('json')
local time = require('time')
local goos = require('goos')
local plugin = 'linux.diskstats'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local manager = helpers.connections.manager
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

if not goos.stat('/proc/diskstats') then
  print('disabled diskstats plugin, because /proc/diskstats not found')
  while true do
    time.sleep(1)
  end
end

local function collect()

  local devices_info, all_stats = {}, {}
  for dev, values in pairs(helpers.linux.disk_stat.read_diskstat()) do
    local mountpoint = helpers.linux.disk_stat.get_mountpoint_by_dev(dev)
    if mountpoint then
      devices_info[dev] = {}
      devices_info[dev]["mountpoint"] = mountpoint
      all_stats[dev] = {
        utilization = values.tot_ticks / 10,
        read_bytes = values.rd_sec_or_wr_ios * 512, read_ops = values.rd_ios,
        write_bytes = values.wr_sec * 512, write_ops = values.wr_ios
      }
      helpers.linux.disk_stat.calc_value(dev, values)
    end
  end

  for dev, info in pairs(devices_info) do
    local mountpoint = info["mountpoint"]
    local utilization, await = 0, nil
    if dev:match("^md") then
      local slaves_info = helpers.linux.disk_stat.md_device_sizes(dev)
      local total_slave_size = 0; for _, size in pairs(slaves_info) do total_slave_size = total_slave_size + size end
      local raid_level = md_level(dev)
      if raid_level then
        -- для raid{0,1} просчитываем utilization с весом
        -- вес высчитывается = (размер slave) / (сумму размера slave-устройств)
        if (raid_level == "raid0") or (raid_level == "raid1") then
          for slave, size in pairs(slaves_info) do
            local weight = size / total_slave_size
            utilization = utilization + (all_stats[slave]["utilization"] * weight)
            local slave_await = helpers.linux.disk_stat.calc_values[slave]["await"]
            if slave_await then
              if await == nil then await = 0 end
              await = await + (slave_await * weight)
            end
          end
        end
      end
    else
      utilization = all_stats[dev]["utilization"]
      await = helpers.linux.disk_stat.calc_values[dev]["await"]
    end
    -- send calculated values
    local jsonb = {mountpoint = mountpoint}
    jsonb.utilization = helpers.metric.speed(plugin.."utilization"..mountpoint, utilization)
    jsonb.await = await
    for _, key in pairs({'read_bytes', 'write_bytes', 'read_ops', 'write_ops'}) do
      jsonb[key] = helpers.metric.speed(plugin..key..mountpoint, all_stats[dev][key])
    end
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    metric_insert(plugin, nil, nil, nil, jsonb)
  end

end

-- run collect
helpers.runner.run_every(collect, 10)
