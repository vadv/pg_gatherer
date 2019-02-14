local function is_rds(agent)
  local _, err = agent:query("show rds.extensions")
  return (not err)
end

return is_rds
