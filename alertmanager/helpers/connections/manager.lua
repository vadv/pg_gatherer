local db = require("db")
local manager, err = db.open("postgres", os.getenv("MANAGER"), {shared=true})
if err then error(err) end
return manager
