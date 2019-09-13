package connection_test

import (
	"testing"

	"github.com/vadv/gopher-lua-libs/inspect"

	"github.com/coins.ph/pg_gatherer/connection"
	lua "github.com/yuin/gopher-lua"
)

func TestConnection(t *testing.T) {

	state := lua.NewState()
	connection.Preload(state)
	connection.New(state, `connection`,
		"/tmp", "coinsph", 5432, "coinsph", "")

	inspect.Preload(state)
	if err := state.DoFile("./tests/connection.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
