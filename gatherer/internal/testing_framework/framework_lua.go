package testing_framework

import (
	"time"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
	lua "github.com/yuin/gopher-lua"
)

// checkUserDataFramework return testing_framework from lua state
func checkUserDataFramework(L *lua.LState, n int) *framework {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*framework); ok {
		return v
	}
	L.ArgError(n, "testing_framework_ud expected")
	return nil
}

func createPlugin(L *lua.LState) int {
	ud := checkUserDataFramework(L, 1)
	if err := ud.pool.AddPluginToHost(ud.pluginName, ud.host); err != nil {
		L.RaiseError("register error: %s", err.Error())
	}
	return 0
}

func removePlugin(L *lua.LState) int {
	ud := checkUserDataFramework(L, 1)
	ud.pool.StopAndRemovePluginFromHost(ud.pluginName, ud.host)
	time.Sleep(time.Second)
	return 0
}

func restartCount(L *lua.LState) int {
	ud := checkUserDataFramework(L, 1)
	stat := getStatistic(L, ud)
	L.Push(lua.LNumber(stat.Starts))
	return 1
}

func errorCount(L *lua.LState) int {
	ud := checkUserDataFramework(L, 1)
	stat := getStatistic(L, ud)
	L.Push(lua.LNumber(stat.Errors))
	return 1
}

func lastError(L *lua.LState) int {
	ud := checkUserDataFramework(L, 1)
	stat := getStatistic(L, ud)
	L.Push(lua.LString(stat.LastError))
	return 1
}

func getStatistic(L *lua.LState, ud *framework) *plugins.PluginStatistic {
	statistic := ud.pool.PluginStatisticPerHost()
	hostPluginStat, okPluginStatForHost := statistic[ud.host]
	if !okPluginStatForHost {
		L.RaiseError("host '%s' not registered", ud.host)
		return nil
	}
	var stat *plugins.PluginStatistic
	for _, plStat := range hostPluginStat {
		if plStat.PluginName == ud.pluginName {
			stat = &plStat
		}
	}
	if stat == nil {
		L.RaiseError("plugin '%s' not found", ud.pluginName)
		return nil
	}
	return stat
}
