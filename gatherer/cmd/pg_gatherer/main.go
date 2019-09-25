package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/vadv/pg_gatherer/gatherer/internal/secrets"

	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
)

var (
	version        = `unknown`
	hostConfigFile = flag.String(`host-config-file`, `host.yaml`, `Path to config file with host configurations.`)
	pluginDir      = flag.String(`plugins-dir`, `./plugins`, `Path to plugins directory`)
	cacheDir       = flag.String(`cache-dir`, `./cache`, `Path to cache directory`)
	httpListen     = flag.String(`http-listen`, `:8080`, `Lister address`)
	secretsFile    = flag.String(`secret-file`, ``, `Path to yaml file with secrets (key:value)`)
	versionFlag    = flag.Bool(`version`, false, `Print version and exit`)
)

func main() {

	if !flag.Parsed() {
		flag.Parse()
	}

	if *versionFlag {
		fmt.Printf("version: %s\n", version)
		os.Exit(0)
	}

	config, errConfig := readConfig(*hostConfigFile)
	if errConfig != nil {
		log.Printf("[FATAL] config file error: %s\n", errConfig.Error())
		os.Exit(1)
	}

	// http
	m := http.NewServeMux()
	httpServer := &http.Server{Addr: *httpListen, Handler: m}
	m.Handle("/", http.RedirectHandler("/metrics", http.StatusFound))
	m.Handle("/metrics", promhttp.Handler())
	go func() {
		if errListen := httpServer.ListenAndServe(); errListen != nil {
			log.Printf("[FATAL] http listen: %s\n", errListen.Error())
			os.Exit(2)
		}
	}()

	// secrets for pool
	secretStorage := secrets.New(*secretsFile)
	// pool of plugins
	pool := plugins.NewPool(*pluginDir, *cacheDir)
	// register plugins
	if errRegister := config.registerHostsAndPlugins(pool, secretStorage); errRegister != nil {
		log.Printf("[FATAL] register: %s\n", errRegister.Error())
		os.Exit(3)
	}
	go prometheusCollectPoolStatistics(pool)
	log.Printf("[INFO] started\n")

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)

	for {
		s := <-sig
		switch s {
		case syscall.SIGHUP:
			// reload
			log.Printf("[INFO] reloading\n")
			secretStorage.Read()
			newConfig, errConfigReRead := readConfig(*hostConfigFile)
			if errConfigReRead != nil {
				log.Printf("[FATAL] config file error: %s\n", errConfigReRead.Error())
				os.Exit(4)
			}
			config = newConfig
			if errUnRegister := config.unregisterAll(pool); errUnRegister != nil {
				log.Printf("[FATAL] unregister error: %s\n", errUnRegister.Error())
				os.Exit(5)
			}
			if errRegister := config.registerHostsAndPlugins(pool, secretStorage); errRegister != nil {
				log.Printf("[FATAL] register error: %s\n", errRegister.Error())
				os.Exit(5)
			}
			log.Printf("[INFO] reloaded\n")
		case syscall.SIGINT, syscall.SIGTERM:
			// stop
			log.Printf("[INFO] shutdown\n")
			for host, _ := range *config {
				pool.RemoveHostAndPlugins(host)
			}
			log.Printf("[INFO] stopped\n")
			return
		}
	}

}
