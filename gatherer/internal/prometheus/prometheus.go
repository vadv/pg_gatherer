package prometheus

import lua "github.com/yuin/gopher-lua"

// Preload is the preloader of user data prometheus_metric_ud.
func Preload(L *lua.LState) int {
	prometheusUD := L.NewTypeMetatable(`prometheus_metric_ud`)
	L.SetGlobal(`prometheus_metric_ud`, prometheusUD)
	L.SetField(prometheusUD, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"set": Set,
		"get": Inc,
		"add": Add,
	}))
	L.SetGlobal("prometheus_counter", L.NewFunction(Counter))
	L.SetGlobal("prometheus_gauge", L.NewFunction(Gauge))
	return 0
}
