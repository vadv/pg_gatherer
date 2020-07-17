FROM golang:1.14 as builder

WORKDIR /go/github.com/vadv/pg_gatherer

COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

COPY . .
RUN make build

FROM centos:7

ENV LC_ALL=en_US.UTF-8
COPY --from=builder /go/github.com/vadv/pg_gatherer/bin/pg_gatherer /usr/bin/pg_gatherer
COPY --from=builder /go/github.com/vadv/pg_gatherer/plugins /etc/pg_gatherer/plugins
