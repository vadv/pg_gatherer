package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/vadv/pg_gatherer/gatherer/internal/secrets"

	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"

	"gopkg.in/yaml.v2"
)

var (
	version        = `unknown`
	hostConfigFile = flag.String(`host-config`, `host.yaml`, `Path to config file with host configurations.`)
	pluginDir      = flag.String(`plugins`, `./plugins`, `Path to plugins directory`)
	cacheDir       = flag.String(`cache`, `./cache`, `Path to cache directory`)
	httpListen     = flag.String(`http-listen`, `:8080`, `Lister address`)
	secretsFile    = flag.String(`secrets`, ``, `Path to yaml file with secrets (key:value)`)
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

	data, err := ioutil.ReadFile(*hostConfigFile)
	if err != nil {
		log.Printf("[FATAL] read config '%s': %s\n", *hostConfigFile, err.Error())
		os.Exit(1)
	}
	config := new(Config)
	if errMarshal := yaml.Unmarshal(data, &config); errMarshal != nil {
		log.Printf("[FATAL] parse config '%s': %s\n", *hostConfigFile, errMarshal.Error())
		os.Exit(1)
	}
	if errConfig := config.validate(); errConfig != nil {
		log.Printf("[FATAL] config has error: %s\n", errConfig.Error())
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

	// secrets
	secretStorage := secrets.New(*secretsFile)

	pool := plugins.NewPool(*pluginDir, *cacheDir)
	// register
	for host, hostConfig := range *config {
		log.Printf("[INFO] register host: '%s'\n", host)
		pool.RegisterHost(host, hostConfig.Connections)
		for _, pl := range hostConfig.Plugins {
			log.Printf("[INFO] register plugin '%s' for host: '%s'\n", pl, host)
			if errPl := pool.AddPluginToHost(pl, host, secretStorage); errPl != nil {
				log.Printf("[FATAL] register plugin '%s' for host '%s': %s\n",
					pl, host, errPl.Error())
				os.Exit(3)
			}
		}
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
			log.Printf("[INFO] reload\n")
			secretStorage.Read()
			for host, hostConfig := range *config {
				for _, pl := range hostConfig.Plugins {
					log.Printf("[INFO] unregister plugin '%s' for host: '%s'\n", pl, host)
					if errRemove := pool.StopAndRemovePluginFromHost(pl, host); errRemove != nil {
						log.Printf("[FATAL] stop plugin '%s' for host '%s': %s\n", pl, host, errRemove.Error())
						os.Exit(3)
					}
					log.Printf("[INFO] register plugin '%s' for host: '%s'\n", pl, host)
					if errPl := pool.AddPluginToHost(pl, host, secretStorage); errPl != nil {
						log.Printf("[FATAL] register plugin '%s' for host '%s': %s\n",
							pl, host, errPl.Error())
						os.Exit(3)
					}
				}
			}
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
