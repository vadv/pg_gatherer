package plugins_test

import (
	"os"
	"strings"
	"testing"
	"time"

	"github.com/vadv/pg_gatherer/internal/plugins"
)

func TestPool(t *testing.T) {

	pool := plugins.NewPool("./test/", "./test/cache")
	conn := &plugins.Connection{
		Host:     "/tmp",
		DBName:   "gatherer",
		Port:     5432,
		UserName: "gatherer",
	}
	pool.AddHost("localhost-test", conn, conn)

	// delete caches
	os.RemoveAll("./test/cache")

	// add pl_cache
	if err := pool.AddPluginToHost("pl_cache", "localhost-test"); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_restarts
	if err := pool.AddPluginToHost("pl_restarts", "localhost-test"); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_pg
	if err := pool.AddPluginToHost("pl_pg", "localhost-test"); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	time.Sleep(5 * time.Second)

	stat := pool.PluginStatisticPerHost()
	for _, pl := range stat["localhost-test"] {

		// pl_pg
		if pl.PluginName == `pl_pg` {
			if pl.Errors > 0 {
				t.Fatalf("plugin pl_pg must not restarted with error: %d\n", pl.Errors)
			}
		}

		// pl_cache
		if pl.PluginName == `pl_cache` {
			if pl.Errors > 0 {
				t.Fatalf("plugin pl_cache must not restarted with error: %d\n", pl.Errors)
			}
			if pl.Starts != 3 {
				t.Fatalf("plugin pl_cache must start only 3 times: %d\n", pl.Starts)
			}
		}

		// pl_restarts
		if pl.PluginName == `pl_restarts` {
			if pl.Errors != 1 {
				t.Fatalf("plugin pl_restarts must errored 1 times: %d\n", pl.Errors)
			}
			if pl.Starts != 3 {
				t.Fatalf("plugin pl_restarts must start only 3 times: %d\n", pl.Starts)
			}
			if !strings.Contains(pl.LastError, `error anchor-test-restarts`) {
				t.Fatalf("plugin pl_restarts: %s\n", pl.LastError)
			}
		}
	}

}
