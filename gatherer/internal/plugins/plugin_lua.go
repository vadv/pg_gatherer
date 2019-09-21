package plugins

import (
	"path/filepath"

	lua "github.com/yuin/gopher-lua"
)

func checkPlugin(L *lua.LState, n int) *plugin {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*plugin); ok {
		return v
	}
	L.ArgError(n, "plugin_status_ud expected")
	return nil
}

// return plugin name
func pluginName(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	L.Push(lua.LString(p.config.pluginName))
	return 1
}

// return plugin dir
func pluginDir(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	dir := filepath.Join(p.config.rootDir, p.config.pluginName)
	L.Push(lua.LString(dir))
	return 1
}

// plugin host
func pluginHost(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	L.Push(lua.LString(p.config.host))
	return 1
}

// error count
func pluginErrorCount(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	L.Push(lua.LNumber(p.statistics.Errors))
	return 1
}

// start count
func pluginStartCount(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	L.Push(lua.LNumber(p.statistics.Starts))
	return 1
}

// last error
func pluginLastError(L *lua.LState) int {
	p := checkPlugin(L, 1)
	p.mutex.Lock()
	defer p.mutex.Unlock()
	if p.statistics.LastError != `` {
		L.Push(lua.LString(p.statistics.LastError))
		return 1
	}
	return 0
}
