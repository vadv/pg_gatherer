test_in_docker:
	./tests/postgresql.sh
	go test -v -race ./...
	go build -o ./bin/testing --tags netcgo ./cmd/testing/
	./bin/testing --plugin-dir ./plugins --host /tmp --dbname gatherer --username gatherer

build:
	go build -o ./bin/server --tags netcgo ./cmd/server/