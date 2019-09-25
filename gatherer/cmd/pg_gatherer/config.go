package main

import (
	"fmt"
	"io/ioutil"
	"log"

	"github.com/vadv/pg_gatherer/gatherer/internal/secrets"

	"gopkg.in/yaml.v2"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
)

// Config represent configuration of plugins
type Config map[string]HostConfiguration

// HostConfiguration represent configurations of hosts
type HostConfiguration struct {
	Plugins     []string                       `yaml:"plugins,omitempty"`
	Connections map[string]*plugins.Connection `yaml:"connections"`
}

func readConfig(configFile string) (*Config, error) {
	data, err := ioutil.ReadFile(configFile)
	if err != nil {
		return nil, err
	}
	config := new(Config)
	if errMarshal := yaml.Unmarshal(data, &config); errMarshal != nil {
		return nil, errMarshal
	}
	if errConfig := config.validate(); errConfig != nil {
		return nil, errConfig
	}
	return config, nil
}

func (c Config) registerHostsAndPlugins(pool *plugins.Pool, secretStorage *secrets.Storage) error {
	for host, hostConfig := range c {
		log.Printf("[INFO] register host: '%s'\n", host)
		pool.RegisterHost(host, hostConfig.Connections)
		for _, pl := range hostConfig.Plugins {
			log.Printf("[INFO] register plugin '%s' for host: '%s'\n", pl, host)
			if errPl := pool.AddPluginToHost(pl, host, secretStorage); errPl != nil {
				return fmt.Errorf("register plugin '%s' for host '%s': %s\n",
					pl, host, errPl.Error())
			}
		}
	}
	return nil
}

func (c Config) unregisterAll(pool *plugins.Pool) error {
	for host, hostConfig := range c {
		for _, pl := range hostConfig.Plugins {
			log.Printf("[INFO] unregister plugin '%s' for host: '%s'\n", pl, host)
			if errRemove := pool.StopAndRemovePluginFromHost(pl, host); errRemove != nil {
				return fmt.Errorf("stop plugin '%s' for host '%s': %s\n", pl, host, errRemove.Error())
			}
		}
	}
	return nil
}

func (c Config) validate() error {
	if len(c) == 0 {
		return fmt.Errorf("hosts configuration is empty")
	}
	for host, config := range c {
		if len(config.Plugins) == 0 {
			return fmt.Errorf("plugins is empty for host: %s", host)
		}
	}
	return nil
}
