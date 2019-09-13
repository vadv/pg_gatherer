package connection_test

import (
	"testing"

	"github.com/vadv/gopher-lua-libs/inspect"

	"github.com/vadv/pg_gatherer/internal/connection"
	lua "github.com/yuin/gopher-lua"
)

func TestConnection(t *testing.T) {

	state := lua.NewState()
	connection.Preload(state)
	connection.New(state, `connection`,
		"/tmp", "gatherer", 5432, "gatherer", "")

	inspect.Preload(state)
	if err := state.DoFile("./tests/connection.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
