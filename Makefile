test_compose:
	docker-compose -f docker/docker-compose.yml up

go_test:
	./tests/postgresql.sh
	go test -v -race ./...