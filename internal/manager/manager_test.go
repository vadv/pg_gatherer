package manager_test

import (
	"testing"

	"github.com/vadv/gopher-lua-libs/inspect"
	"github.com/vadv/pg_gatherer/internal/connection"
	"github.com/vadv/pg_gatherer/internal/manager"
	lua "github.com/yuin/gopher-lua"
)

func TestManager(t *testing.T) {

	state := lua.NewState()
	manager.Preload(state)
	manager.New(state, `manager`, "host=/tmp dbname=gatherer user=gatherer")
	connection.Preload(state)
	connection.New(state, `connection`,
		"/tmp", "gatherer", 5432, "gatherer", "")

	inspect.Preload(state)
	if err := state.DoFile("./tests/manager.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
