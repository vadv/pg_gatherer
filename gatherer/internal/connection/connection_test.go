package connection_test

import (
	"testing"

	"github.com/vadv/gopher-lua-libs/time"

	"github.com/vadv/gopher-lua-libs/inspect"

	"github.com/vadv/pg_gatherer/gatherer/internal/connection"
	lua "github.com/yuin/gopher-lua"
)

func TestBuildConnectionString(t *testing.T) {
	params := make(map[string]string)
	params[`10`] = "10"
	params[`11`] = "11"
	first := connection.BuildConnectionString(`host`, `dbname`, 5432, `user`, `password`, params)
	for i := 0; i < 100; i++ {
		second := connection.BuildConnectionString(`host`, `dbname`, 5432, `user`, `password`, params)
		if first != second {
			t.Fatalf("first != second:\nfirst: %s\nsecond: %s\n", first, second)
		}
	}
}

func TestConnection(t *testing.T) {

	state := lua.NewState()
	connection.Preload(state)
	connection.New(state, `connection`,
		"/tmp", "gatherer", "gatherer", "", 5432, nil)

	inspect.Preload(state)
	time.Preload(state)
	if err := state.DoFile("./tests/connection.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
