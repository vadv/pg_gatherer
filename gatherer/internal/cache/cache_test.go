package cache_test

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/vadv/gopher-lua-libs/inspect"
	"github.com/vadv/gopher-lua-libs/time"
	lua "github.com/yuin/gopher-lua"

	"github.com/vadv/pg_gatherer/gatherer/internal/cache"
)

func TestCacheRotate(t *testing.T) {

	state := lua.NewState()
	cache.Preload(state)
	os.RemoveAll("./tests/rotate.sqlite")
	if err := cache.NewSqlite(state, "cache", "./tests/rotate.sqlite", "prefix_"); err != nil {
		t.Fatalf(err.Error())
	}
	time.Preload(state)
	inspect.Preload(state)
	if err := state.DoFile("./tests/rotate.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}

func TestCache(t *testing.T) {

	state := lua.NewState()
	cache.Preload(state)
	os.RemoveAll("./tests/db.sqlite")
	if err := cache.NewSqlite(state, "cache", "./tests/db.sqlite", "prefix_"); err != nil {
		t.Fatalf(err.Error())
	}
	time.Preload(state)
	inspect.Preload(state)
	if err := state.DoFile("./tests/cache.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}

func TestCorrupt(t *testing.T) {
	state := lua.NewState()
	cache.Preload(state)
	os.RemoveAll("./tests/corrupt.sqlite")
	if err := ioutil.WriteFile("./tests/corrupt.sqlite", []byte("<bug>"), 0600); err != nil {
		t.Fatalf(err.Error())
	}
	if err := cache.NewSqlite(state, "cache", "./tests/corrupt.sqlite", "prefix_"); err != nil {
		t.Fatalf(err.Error())
	}
	time.Preload(state)
	inspect.Preload(state)
	if err := state.DoFile("./tests/cache.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}
}
