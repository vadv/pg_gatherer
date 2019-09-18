test_in_docker:
	./tests/postgresql.sh
	go test -v -race ./...

build:
	go build -o ./bin/server --tags netcgo ./cmd/