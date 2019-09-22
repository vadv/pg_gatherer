package main

import (
	"time"

	"github.com/prometheus/client_golang/prometheus"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
)

func prometheusCollectPoolStatistics(pool *plugins.Pool) {

	errorsVec := prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Namespace: "pg_gatherer",
		Name:      "plugin_errors",
		Help:      "Count of plugins errors",
	}, []string{"host", "plugin"})
	prometheus.MustRegister(errorsVec)

	for {
		errorStat := make(map[string]map[string]int, 0)
		for host, hostStats := range pool.PluginStatisticPerHost() {
			errorStat[host] = make(map[string]int, 0)
			for _, stat := range hostStats {
				errorStat[host][stat.PluginName] = stat.Errors
			}
		}
		for host, pluginStat := range errorStat {
			for plugin, errors := range pluginStat {
				errorsVec.With(map[string]string{"host": host, "plugin": plugin}).Set(float64(errors))
			}
		}
		time.Sleep(5 * time.Second)
	}

}
