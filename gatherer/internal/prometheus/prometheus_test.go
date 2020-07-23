package prometheus_test

import (
	"net/http"
	"path/filepath"
	"testing"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	libs "github.com/vadv/gopher-lua-libs"
	"github.com/vadv/gopher-lua-libs/inspect"
	lua "github.com/yuin/gopher-lua"

	"github.com/vadv/pg_gatherer/gatherer/internal/prometheus"
)

var testsList = []string{
	"gauge.lua",
	"counter.lua",
}

func TestPrometheus(t *testing.T) {
	http.Handle("/metrics", promhttp.Handler())
	go func() {
		if errListen := http.ListenAndServe(":9091", nil); errListen != nil {
			panic(errListen.Error())
		}
	}()
	for _, test := range testsList {
		state := lua.NewState()
		prometheus.Preload(state)
		inspect.Preload(state)
		libs.Preload(state)
		if err := state.DoFile(filepath.Join("tests", "helper.lua")); err != nil {
			t.Fatalf(err.Error())
		}
		if err := state.DoFile(filepath.Join("tests", test)); err != nil {
			t.Fatalf(err.Error())
		}
		state.Close()
	}
}
