test_in_docker:
	./tests/postgresql.sh
	go test -v -race ./...
