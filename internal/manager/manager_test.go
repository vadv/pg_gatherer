package manager_test

import (
	"testing"

	"github.com/vadv/pg_gatherer/internal/connection"
	"github.com/vadv/pg_gatherer/internal/manager"
	"github.com/vadv/gopher-lua-libs/inspect"
	lua "github.com/yuin/gopher-lua"
)

func TestManager(t *testing.T) {

	state := lua.NewState()
	manager.Preload(state)
	manager.New(state, `manager`, "host=/tmp dbname=coinsph user=coinsph")
	connection.Preload(state)
	connection.New(state, `connection`,
		"/tmp", "coinsph", 5432, "coinsph", "")

	inspect.Preload(state)
	if err := state.DoFile("./tests/manager.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
