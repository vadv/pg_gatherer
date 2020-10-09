package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	libs "github.com/vadv/gopher-lua-libs"
	lua "github.com/yuin/gopher-lua"

	"github.com/vadv/pg_gatherer/gatherer/internal/connection"
	"github.com/vadv/pg_gatherer/gatherer/internal/testing_framework"
)

var (
	pluginPath       = flag.String(`plugin-dir`, `plugins`, `Path to plugin directory`)
	cachePath        = flag.String(`cache-dir`, `plugins\cache`, `Path to cache directory`)
	stopOnFirstError = flag.Bool(`stop-on-first-error`, false, `Stop on first error`)
	hostName         = flag.String(`host`, os.Getenv(`PGHOST`), `PostgreSQL host`)
	dbName           = flag.String(`dbname`, os.Getenv(`PGDATABASE`), `PostgreSQL database`)
	userName         = flag.String(`username`, os.Getenv(`PGUSER`), `PostgreSQL user`)
	password         = flag.String(`password`, os.Getenv(`PGPASSWORD`), `PostgreSQL password`)
	dbPort           = flag.Int(`port`, 5432, `PostgreSQL port`)
)

type testResult struct {
	pluginName string
	testFile   string
	err        error
}

func main() {
	if !flag.Parsed() {
		flag.Parse()
	}
	startAt := time.Now()
	// load embedded plugins
	plugins, err := listOfPluginsAndTestFiles(filepath.Join(*pluginPath, "embedded"))
	if err != nil {
		log.Printf("[ERROR] get embedded plugins: %s\n", err.Error())
		plugins = make(map[string]string)
	}
	// load override plugins
	overridePlugins, errOverridePlugins := listOfPluginsAndTestFiles(*pluginPath)
	if errOverridePlugins == nil {
		for plugin, file := range overridePlugins {
			plugins[plugin] = file
		}
	}

	var wg sync.WaitGroup
	wg.Add(len(plugins))
	log.Printf("[INFO] test %d plugins\n", len(plugins))
	testResultChan := make(chan *testResult)

	for plugin, testFile := range plugins {
		go func(plugin, testFile string) {
			log.Printf("[INFO] start testing plugin %s via file %s\n", plugin, testFile)
			errTest := testPlugin(*pluginPath, *cachePath, plugin, testFile)
			log.Printf("[INFO] test plugin %s via file %s: was completed\n", plugin, testFile)
			testResultChan <- &testResult{
				pluginName: plugin,
				testFile:   testFile,
				err:        errTest,
			}
		}(plugin, testFile)
	}

	failed, completed := int32(0), int32(0)
	go func() {
		ticker := time.NewTicker(time.Second)
		for {
			select {
			case result := <-testResultChan:
				atomic.AddInt32(&completed, 1)
				if result != nil && result.err != nil {
					atomic.AddInt32(&failed, 1)
					log.Printf("[ERROR] plugin '%s' file '%s' error:\n%s\n",
						result.pluginName, result.testFile, result.err.Error())
					if *stopOnFirstError {
						os.Exit(1)
					}
				}
				wg.Done()
			case <-ticker.C:
				log.Printf("[INFO] already processing\t%.0fs:\ttotal: %d\tcompleted: %d\tfailed: %d\n",
					time.Since(startAt).Seconds(), len(plugins), completed, failed)
			}
		}
	}()

	wg.Wait()
	if failed > 0 {
		log.Printf("[ERROR] %d plugin(s) was failed\n", failed)
		os.Exit(int(failed))
	} else {
		log.Printf("[INFO] was competed after: %v\n", time.Since(startAt))
	}
}

func testPlugin(pluginDir, cacheDir, pluginName, testFile string) error {
	state := lua.NewState()
	libs.Preload(state)
	testing_framework.Preload(state)
	if err := testing_framework.New(state, pluginDir, cacheDir, pluginName,
		*hostName, *dbName, *userName, *password, *dbPort, nil); err != nil {
		return err
	}
	connection.Preload(state)
	connection.New(state, `target`,
		*hostName, *dbName, *userName, *password, *dbPort, nil)
	connection.New(state, `storage`,
		*hostName, *dbName, *userName, *password, *dbPort, nil)
	if err := state.DoFile(filepath.Join(pluginDir, "init.test.lua")); err != nil {
		return err
	}
	return state.DoFile(testFile)
}

func listOfPluginsAndTestFiles(dir string) (map[string]string, error) {
	pattern := filepath.Join(dir, "*", "test.lua")
	testFiles, err := filepath.Glob(pattern)
	if err != nil {
		return nil, err
	}
	result := make(map[string]string)
	for _, f := range testFiles {
		pluginDir, _ := filepath.Split(f)
		split := strings.Split(pluginDir, string(filepath.Separator))
		if len(split) < 3 {
			return nil, fmt.Errorf("splited: %v", split)
		}
		plugin := split[len(split)-2]
		result[plugin] = f
	}
	return result, nil
}
