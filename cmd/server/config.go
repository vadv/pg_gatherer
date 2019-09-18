package main

import (
	"fmt"

	"github.com/vadv/pg_gatherer/internal/plugins"
)

// Config represent configuration of plugins
type Config struct {
	PluginsDir string               `yaml:"plugins_dir"`
	CacheDir   string               `yaml:"cache_dir"`
	Hosts      []HostConfigurations `yaml:"hosts"`
}

// HostConfigurations represent configurations of hosts
type HostConfigurations struct {
	Host    string              `yaml:"host"`
	Plugins []string            `yaml:"plugins,omitempty"`
	Manager *plugins.Connection `yaml:"manager"`
	Agent   *plugins.Connection `yaml:"agent"`
}

func (c *Config) validate() error {
	if len(c.Hosts) == 0 {
		return fmt.Errorf("`hosts` is empty")
	}
	for _, h := range c.Hosts {
		if h.Host == `` {
			return fmt.Errorf("found empty hosts")
		}
		if len(h.Plugins) == 0 {
			return fmt.Errorf("plugins is empty for host: %s", h.Host)
		}
		if h.Manager == nil {
			return fmt.Errorf("empty manager connection for host: %s", h.Host)
		}
		if h.Agent == nil {
			return fmt.Errorf("empty agent information for host: %s", h.Host)
		}
	}
	return nil
}
