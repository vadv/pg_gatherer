test_in_docker:
	# init && start database
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/initdb -D /tmp/db'
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl start -W -D /tmp/db'
	sleep 3
	# prepare database gatherer
	psql -U postgres -Atc "create user gatherer"
	psql -U postgres -Atc "create database gatherer owner gatherer"
	psql -U postgres -Atc "grant pg_monitor to gatherer"
	psql -U gatherer -At -1 -f ./schema/schema.sql -d gatherer
	# install extensions
	psql -U postgres -d gatherer -Atc "create extension pg_buffercache"
	psql -U postgres -d gatherer -Atc "create extension pg_stat_statements"
	psql -U postgres -Atc  "alter system set shared_preload_libraries TO 'pg_stat_statements'"
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl start -W -D /tmp/db'
	sleep 3
	# start tests
	go test -v -race ./...
	go build -o ./bin/testing --tags netcgo ./cmd/testing/
	./bin/testing --plugin-dir ./plugins --cache-dir /tmp/cache --host /tmp --dbname gatherer --username gatherer

build:
	go build -o ./bin/server --tags netcgo ./cmd/server/