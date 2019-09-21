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

	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"

	"gopkg.in/yaml.v2"
)

var (
	version     = `unknown`
	configPath  = flag.String(`config`, `config.yaml`, `Path to config file`)
	versionFlag = flag.Bool(`version`, false, `Print version and exit`)
)

func main() {

	if !flag.Parsed() {
		flag.Parse()
	}

	if *versionFlag {
		fmt.Printf("version: %s\n", version)
		os.Exit(0)
	}

	data, err := ioutil.ReadFile(*configPath)
	if err != nil {
		log.Printf("[FATAL] read config '%s': %s\n", *configPath, err.Error())
		os.Exit(1)
	}
	config := &Config{}
	if errMarshal := yaml.Unmarshal(data, config); errMarshal != nil {
		log.Printf("[FATAL] parse config '%s': %s\n", *configPath, errMarshal.Error())
		os.Exit(1)
	}
	if errConfig := config.validate(); errConfig != nil {
		log.Printf("[FATAL] config has error: %s\n", errConfig.Error())
		os.Exit(1)
	}

	// http
	m := http.NewServeMux()
	httpServer := &http.Server{Addr: config.HttpListen, Handler: m}
	m.Handle("/", http.RedirectHandler("/metrics", http.StatusFound))
	m.Handle("/metrics", promhttp.Handler())
	go func() {
		if errListen := httpServer.ListenAndServe(); errListen != nil {
			log.Printf("[FATAL] http listen: %s\n", errListen.Error())
			os.Exit(2)
		}
	}()

	pool := plugins.NewPool(config.PluginsDir, config.CacheDir)
	for host, hostConfig := range config.Hosts {
		log.Printf("[INFO] register host: '%s'\n", host)
		pool.RegisterHost(host, hostConfig.Connections)
		for _, pl := range hostConfig.Plugins {
			log.Printf("[INFO] register plugin '%s' for host: '%s'\n", pl, host)
			if errPl := pool.AddPluginToHost(pl, host); errPl != nil {
				log.Printf("[FATAL] register plugin '%s' for host '%s': %s\n",
					pl, host, errPl.Error())
				os.Exit(3)
			}
		}
	}
	log.Printf("[INFO] started\n")

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig

	log.Printf("[INFO] shutdown\n")
	for host, _ := range config.Hosts {
		pool.RemoveHostAndPlugins(host)
	}
	log.Printf("[INFO] stopped\n")

}
