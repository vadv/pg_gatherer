local db = require("db")
local agent, err = db.open("postgres", os.getenv("CONNECTION_AGENT"), {shared=true})
if err then error(err) end
return agent
