local db = require("db")
local manager, err = db.open("postgres", os.getenv("CONNECTION_MANAGER"), {shared=true})
if err then error(err) end
return manager
