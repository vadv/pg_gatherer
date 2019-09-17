package plugins_test

import (
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
	pool.AddHost("localhost", conn, conn)
	if err := pool.AddPluginToHost("plugin_name", "localhost"); err != nil {
		t.Fatalf("add plugin: %s\n", err.Error())
	}
	time.Sleep(10 * time.Second)

}
