build:
	go build -o ./bin/server --tags netcgo ./gatherer/cmd/server/

dashboard: submodule_check
	jsonnet -J ./grafana/jsonnet ./grafana/jsonnet/dashboard.jsonnet -o ./gatherer/dashboard.json

submodules:
	git submodule init
	git submodule update

submodule_update:
	git submodule update

submodule_pull:
	git submodule foreach "git pull"

submodule_check:
	@-test -d .git -a .gitmodules && \
		git submodule status \
		| grep -q "^-" \
		&& $(MAKE) submodules || true
	@-test -d .git -a .gitmodules && \
		git submodule status \
		| grep -q "^+" \
		&& $(MAKE) submodule_update || true

test_in_docker:
	# init && start database
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/initdb -D /tmp/db'
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl start -W -D /tmp/db'
	sleep 3
	# change preload libraries
	psql -U postgres -Atc  "alter system set shared_preload_libraries TO pg_stat_statements, timescaledb"
	sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl restart -W -D /tmp/db'
	sleep 3
	# create user && database
	psql -U postgres -Atc "create user gatherer"
	psql -U postgres -Atc "create database gatherer owner gatherer"
	psql -U postgres -Atc "grant pg_monitor to gatherer"
	# install extensions
	psql -U postgres -d gatherer -Atc "create extension pg_buffercache"
	psql -U postgres -d gatherer -Atc "create extension pg_stat_statements"
	psql -U postgres -d gatherer -Atc "create extension timescaledb"
	# update statistics
	/usr/pgsql-11/bin/pgbench -U postgres -h /tmp -i -s 2 postgres
	/usr/pgsql-11/bin/pgbench -U postgres -h /tmp -i -s 2 gatherer
	/usr/pgsql-11/bin/pgbench -U postgres -h /tmp -T 5 postgres
	/usr/pgsql-11/bin/pgbench -U postgres -h /tmp -T 5 gatherer
	/usr/pgsql-11/bin/vacuumdb --analyze-only -U postgres -h /tmp --all
	# deploy schema gatherer
	psql -U gatherer -At -1 -f ./schema/schema.sql -d gatherer
	# start tests
	go test -v -race ./...
	go build -o ./bin/testing --tags netcgo ./gatherer/cmd/testing/
	./bin/testing --plugin-dir ./plugins --cache-dir /tmp/cache --host /tmp --dbname gatherer --username gatherer