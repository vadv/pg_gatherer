# Plugin

The plugin is the directory where the plugin.lua file must be located.
Each plugin lives in a separate lua-state, before starting it reads [init.lua](init.lua).
Lua 5.1 and all libraries from [glua-libs](https://github.com/vadv/gopher-lua-libs) are available in plugin.