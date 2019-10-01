local cloudwatch  = require("cloudwatch")
local plugin_name = 'pg.cloudwatch'
local every       = 5 * 60
local last_time   = time.unix() - every - 60
local metrics     = {
  burst_balance               = "BurstBalance", cpu_credit_balance = "CPUCreditBalance",
  cpu_credit_usage            = "CPUCreditUsage", cpu_surplus_credit_balance = "CPUSurplusCreditBalance",
  cpu_surplus_credits_charged = "CPUSurplusCreditsCharged",
  cpu_utilization             = "CPUUtilization",
  db_load                     = "DBLoad", db_load_cpu = "DBLoadCPU",
  db_load_non_cpu             = "DBLoadNonCPU",
  disk_queue_depth            = "DiskQueueDepth",
  free_storage_space          = "FreeStorageSpace",
  freeable_memory             = "FreeableMemory",
  network_receive_throughput  = "NetworkReceiveThroughput", network_transmit_throughput = "NetworkTransmitThroughput",
  read_iops                   = "ReadIOPS", read_latency = "ReadLatency", read_throudhput = "ReadThroughput",
  replication_slot_disk_usage = "ReplicationSlotDiskUsage",
  transaction_logs_disk_usage = "TransactionLogsDiskUsage",
  swap_usage                  = "SwapUsage",
  write_iops                  = "WriteIOPS", write_latency = "WriteLatency", write_throughput = "WriteThroughput",
}

local clw, err    = cloudwatch.new()
if err then error(err) end

local queries = {}
for name, metric in pairs(metrics) do
  queries[name] = {
    namespace       = "AWS/RDS",
    metric          = metric,
    dimension_name  = "DBInstanceIdentifier",
    dimension_value = plugin:host(),
    stat            = "Average",
    period          = 60,
  }
end

function collect()
  local end_time    = time.unix() - 60
  local result, err = clw:get_metric_data({
    start_time = last_time,
    end_time   = end_time,
    queries    = queries,
  })
  if err then error(err) end
  for name, time_value in pairs(result) do
    for t, v in pairs(time_value) do
      -- print(name, t, v)
      storage_insert_metric({ plugin = plugin_name .. "." .. name, snapshot = t, float = v })
    end
  end
  last_time = end_time
end

run_every(collect, every)