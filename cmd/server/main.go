package main

import (
	"flag"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/vadv/pg_gatherer/internal/plugins"

	"gopkg.in/yaml.v2"
)

var (
	configPath = flag.String(`config`, `config.yaml`, `Path to config file`)
)

func main() {
	if !flag.Parsed() {
		flag.Parse()
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

	pool := plugins.NewPool(config.PluginsDir, config.CacheDir)
	for _, hostConfig := range config.Hosts {
		host := hostConfig.Host
		log.Printf("[INFO] register host: '%s'\n", host)
		pool.RegisterHost(host, hostConfig.Agent, hostConfig.Manager)
		for _, pl := range hostConfig.Plugins {
			log.Printf("[INFO] register plugin '%s' for host: '%s'\n", pl, host)
			if errPl := pool.AddPluginToHost(pl, host); errPl != nil {
				log.Printf("[FATAL] register plugin '%s' for host '%s': %s\n",
					pl, host, errPl.Error())
				os.Exit(2)
			}
		}
	}
	log.Printf("[INFO] started\n")

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig

	log.Printf("[INFO] shutdown\n")
	for _, hostConfig := range config.Hosts {
		pool.RemoveHostAndPlugins(hostConfig.Host)
	}
	log.Printf("[INFO] stopped\n")

}
