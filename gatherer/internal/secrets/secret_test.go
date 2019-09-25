package secrets_test

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/vadv/pg_gatherer/gatherer/internal/secrets"

	"github.com/vadv/gopher-lua-libs/inspect"
	"github.com/vadv/gopher-lua-libs/time"
	lua "github.com/yuin/gopher-lua"
)

func TestCache(t *testing.T) {

	state := lua.NewState()
	secrets.Preload(state)

	s1 := secrets.New("./tests/secrets.yaml")
	s1.Register(state, `secrets_1`)
	time.Preload(state)
	inspect.Preload(state)

	if err := state.DoFile("./tests/secrets.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

	reloadSecretFile := "./tests/secrets_reload.yaml"
	reloadSecretFileData := "set_after_reload: ok\n"
	os.RemoveAll(reloadSecretFile)
	s2 := secrets.New(reloadSecretFile)
	s2.Register(state, `secrets_2`)
	if err := state.DoFile("./tests/reload_1.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}
	if err := ioutil.WriteFile(reloadSecretFile, []byte(reloadSecretFileData), 0644); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}
	s2.Read()
	if err := state.DoFile("./tests/reload_2.lua"); err != nil {
		t.Fatalf("error: %s\n", err.Error())
	}

}
