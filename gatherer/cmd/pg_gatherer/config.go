package main

import (
	"fmt"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
)

// Config represent configuration of plugins
type Config map[string]HostConfiguration

// HostConfiguration represent configurations of hosts
type HostConfiguration struct {
	Plugins     []string                       `yaml:"plugins,omitempty"`
	Connections map[string]*plugins.Connection `yaml:"connections"`
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
