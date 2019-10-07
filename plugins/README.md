# Plugin

* The plugin is the directory where the plugin.lua file must be located.
* If plugin raise error, it will automatically restart.
* Each plugin lives in a separate lua-state.
* Before each start of plugin [init.lua](init.lua) is execute.


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

For each plugin, an table in sqlite is created in which it is possible to store information in a key-value format.
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

## Plugin alerts

This is a special plugin that must be run in one instance, for example, on storage.
The plugin analyzes the information which saved other plugins and creates entries in the storage database,
which will be sent using the sender plugin.

## Plugin sender

This plugin integrates with other types of monitoring: currently it sends information from `alerts` plugin to [PagerDuty](https://pagerduty.com)
and also sends messages to [telegram im](http://telegram.org) if you need it.