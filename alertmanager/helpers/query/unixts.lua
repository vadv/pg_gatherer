local function unixts(manager)
  local result, err = manager:query("select extract(epoch from current_timestamp)::bigint")
  if err then error(err) end
  return tonumber(result.rows[1][1])
end

return unixts
