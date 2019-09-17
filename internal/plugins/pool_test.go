package plugins_test

import (
	"log"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/vadv/pg_gatherer/internal/plugins"
)

const hostname = "localhost-test"

func TestPool(t *testing.T) {

	pool := plugins.NewPool("./test/", "./test/cache")
	conn := &plugins.Connection{
		Host:     "/tmp",
		DBName:   "gatherer",
		Port:     5432,
		UserName: "gatherer",
	}
	pool.AddHost(hostname, conn, conn)

	// delete caches
	os.RemoveAll("./test/cache")

	// add pl_cache
	if err := pool.AddPluginToHost("pl_cache", hostname); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_restarts
	if err := pool.AddPluginToHost("pl_restarts", hostname); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_pg
	if err := pool.AddPluginToHost("pl_pg", hostname); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_rds
	if err := pool.AddPluginToHost("pl_rds", hostname); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	// add pl_run_every
	if err := pool.AddPluginToHost("pl_run_every", hostname); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}

	time.Sleep(5 * time.Second)

	stat := pool.PluginStatisticPerHost()
	for _, pl := range stat[hostname] {

		// pl_pg
		if pl.PluginName == `pl_pg` {
			if pl.Errors > 0 {
				t.Fatalf("must not restarted with error: %d\n", pl.Errors)
			}
		}

		// pl_run_every
		if pl.PluginName == `pl_run_every` {
			if pl.Errors != 1 {
				t.Fatalf("must be 1 time errored: %d\n", pl.Errors)
			}
			if !strings.Contains(pl.LastError, "first error") {
				t.Fatalf("must be error 'first error, but get: %s\n'", pl.LastError)
			}
			if pl.Starts != 2 {
				t.Fatalf("must started 2 times: %d\n", pl.Starts)
			}
		}

		// pl_rds
		if pl.PluginName == `pl_rds` {
			if pl.Errors > 0 {
				t.Fatalf("must not restarted with error: %d\n", pl.Errors)
			}
		}

		// pl_cache
		if pl.PluginName == `pl_cache` {
			if pl.Errors > 0 {
				t.Fatalf("must not restarted with error: %d\n", pl.Errors)
			}
			if pl.Starts != 3 {
				t.Fatalf("must start only 3 times: %d\n", pl.Starts)
			}
		}

		// pl_restarts
		if pl.PluginName == `pl_restarts` {
			if pl.Errors != 1 {
				t.Fatalf("must errored 1 times: %d\n", pl.Errors)
			}
			if pl.Starts != 3 {
				t.Fatalf("must start only 3 times: %d\n", pl.Starts)
			}
			if !strings.Contains(pl.LastError, `error anchor-test-restarts`) {
				t.Fatalf("get error: %s\n", pl.LastError)
			}
		}
	}

	// stop all plugins
	for _, pl := range stat[hostname] {
		log.Printf("stop plugin: %s\n", pl.PluginName)
		if err := pool.StopAndRemovePluginFromHost(pl.PluginName, hostname); err != nil {
			t.Fatalf("stop %s: %s\n", pl.PluginName, err.Error())
		}
	}

	stat = pool.PluginStatisticPerHost()
	if len(stat[hostname]) != 0 {
		t.Fatalf("all plugins must be stopped\n")
	}

}
