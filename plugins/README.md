# Plugin

The plugin is the directory where the plugin.lua file must be located.
Each plugin lives in a separate lua-state, before starting it reads [init.lua](init.lua).

Lua 5.1 and all libraries from [glua-libs](https://github.com/vadv/gopher-lua-libs) are available in plugin.

## Connection

For each connection described in host-config-file you can:

```lua
-- execute read only query:
connection_name:query(query, args1, argN)
-- returns {columns={"name-1", ...} rows={ {0="", 1=""}, {} } }

-- insert metric, table: {plugin="", host="", int=, float=, json=}
-- relevant only for storage connection 
connection_name:insert_metric()
-- returns nil, raise error
```

## Cache

For each plugin, an small database is created in which it is possible to store information in a key-value format.
`cache` is registered as global user-data.

```lua
-- key: string, value: float
cache:set(key, value)
-- returns nil, raise error

-- key: string
cache:get(key)
-- returns value: float, updated_at: float (unix ts)

-- key: string, value: float
cache:diff_and_set(key, value)
-- returns diff between current and previous set value: float, or nil if previous value was doesn't set.

-- key: string, value: float
cache:speed_and_set(key, value)
-- returns speed (current-previous)/(current_time - previous_time): float, or nil if previous value was doesn't set.
```