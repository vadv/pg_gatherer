package testing_framework_test

import (
	"testing"

	libs "github.com/vadv/gopher-lua-libs"

	"github.com/vadv/pg_gatherer/internal/testing_framework"
	lua "github.com/yuin/gopher-lua"
)

func TestFramework(t *testing.T) {

	state := lua.NewState()

	libs.Preload(state)
	testing_framework.Preload(state)
	testing_framework.New(state, `./tests`, `./tests/cache`, `testing-1`,
		`/tmp`, "gatherer", "gatherer", "", 5432, nil)

	if err := state.DoFile("./tests/testing-1/test.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
