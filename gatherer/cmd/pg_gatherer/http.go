package main

import (
	"net/http"
	"net/http/pprof"
	"strings"
)

func handleHTTP(w http.ResponseWriter, req *http.Request) {

	// debug
	if strings.HasPrefix(req.URL.Path, "/debug/") {
		if strings.HasPrefix(req.URL.Path, "/debug/pprof/symbol") {
			pprof.Symbol(w, req)
			return
		}
		if strings.HasPrefix(req.URL.Path, "/debug/pprof/profile") {
			pprof.Profile(w, req)
			return
		}
		if strings.HasPrefix(req.URL.Path, "/debug/pprof/cmdline") {
			pprof.Cmdline(w, req)
			return
		}
		pprof.Index(w, req)
		return
	}

	http.RedirectHandler("/metrics", http.StatusFound)

}
