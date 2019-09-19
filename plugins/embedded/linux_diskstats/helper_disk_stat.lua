local filepath = require('filepath')
local ioutil   = require('ioutil')
local helper  = {}

local function read_diskstat()
  local result  = {}
  -- https://www.kernel.org/doc/Documentation/ABI/testing/procfs-diskstats
  local pattern = "(%d+)%s+(%d+)%s+(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
  for line in io.lines(HOST_PROC_DIR .. "/diskstats") do
    local major, minor, dev_name,
    rd_ios, rd_merges_or_rd_sec, rd_sec_or_wr_ios, rd_ticks_or_wr_sec,
    wr_ios, wr_merges, wr_sec, wr_ticks, ios_pgr, tot_ticks, rq_ticks = line:match(pattern)
    result[dev_name]                                                  = {
      major            = tonumber(major), minor = tonumber(minor),
      rd_ios           = tonumber(rd_ios), rd_merges_or_rd_sec = tonumber(rd_merges_or_rd_sec),
      rd_sec_or_wr_ios = tonumber(rd_sec_or_wr_ios), rd_ticks_or_wr_sec = tonumber(rd_ticks_or_wr_sec),
      wr_ios           = tonumber(wr_ios), wr_merges = tonumber(wr_merges),
      wr_sec           = tonumber(wr_sec), wr_ticks = tonumber(wr_ticks),
      ios_pgr          = tonumber(ios_pgr), tot_ticks = tonumber(tot_ticks),
      rq_ticks         = tonumber(rq_ticks)
    }
  end
  return result
end
helper.read_diskstat = read_diskstat

-- /dev/sda => mountpoint, /dev/mapper/vg0-lv_slashroot => /
-- мы ищем только прямое совпадение!
local function get_mountpoint_from_mounts(full_dev_name)
  for line in io.lines(HOST_PROC_DIR .. "/mounts") do
    local reg_full_dev_name = full_dev_name:gsub("%-", "%S")
    local mountpoint        = line:match("^" .. reg_full_dev_name .. "%s+(%S+)%s+")
    if mountpoint then return mountpoint end
  end
end

-- sdXD => mountpoint
local function sd_mountpoint(sdX)
  return get_mountpoint_from_mounts(HOST_DEV_DIR .. "/" .. sdX)
end

-- dm-X => mountpoint
local function dm_mountpoint(dmX)
  local name = ioutil.read_file(HOST_SYS_DIR .. "/block/" .. dmX .. "/dm/name"):gsub("^%s+", ""):gsub("%s+$", "")
  if not name then return nil end
  return get_mountpoint_from_mounts(HOST_DEV_DIR .. "/mapper/" .. name)
end

-- mdX => mountpoint
local function md_mountpoint(mdX)
  return get_mountpoint_from_mounts(HOST_DEV_DIR .. "/" .. mdX)
end

-- sd, md, dm => mountpoint
local function get_mountpoint_by_dev(dev)
  if dev:match("^sd") then return sd_mountpoint(dev) end
  if dev:match("^nvme") then return sd_mountpoint(dev) end
  if dev:match("^dm") then return dm_mountpoint(dev) end
  if dev:match("^md") then return md_mountpoint(dev) end
end
helper.get_mountpoint_by_dev = get_mountpoint_by_dev

local function md_device_sizes(mdX)
  local result = {}
  for _, path in pairs(filepath.glob(HOST_SYS_DIR .. "/block/" .. mdX .. "/slaves/*")) do
    local dev   = path:match(HOST_SYS_DIR .. "/block/" .. mdX .. "/slaves/(%S+)$")
    result[dev] = tonumber(ioutil.read_file(path .. "/size"))
  end
  return result
end
helper.md_device_sizes = md_device_sizes

-- mdX => raid0, raid1, ...
local function md_level(mdX)
  local data = ioutil.read_file(HOST_SYS_DIR .. "/block/" .. mdX .. "/md/level")
  if data then
    return data:gsub("%s+$", "")
  else
    return nil
  end
end
helper.md_level    = md_level

helper.calc_values = {}
local function calc_value(dev, values)
  if helper.calc_values[dev] == nil then helper.calc_values[dev] = {} end
  if helper.calc_values[dev]["data"] == nil then helper.calc_values[dev]["data"] = {} end
  -- first run
  if helper.calc_values[dev]["data"]["previous"] == nil then
    helper.calc_values[dev]["data"]["previous"] = values;
    return ;
  end

  local previous, current = helper.calc_values[dev]["data"]["previous"], values

  -- await https://github.com/sysstat/sysstat/blob/v11.5.6/common.c#L816
  local ticks             = ((current.rd_ticks_or_wr_sec - previous.rd_ticks_or_wr_sec) + (current.wr_ticks - previous.wr_ticks))
  local io_sec            = (current.rd_ios + current.wr_ios) - (previous.rd_ios + previous.wr_ios)
  if (io_sec > 0) and (ticks > 0) then helper.calc_values[dev]["await"] = ticks / io_sec end
  if (io_sec == 0) or (ticks == 0) then helper.calc_values[dev]["await"] = 0 end

  -- save
  helper.calc_values[dev]["data"]["previous"] = values
end
helper.calc_value = calc_value

return helper
