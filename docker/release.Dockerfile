FROM golang:1.13 as builder

WORKDIR /go/github.com/vadv/pg_gatherer

COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

COPY . .
RUN make build

FROM alpine
COPY --from=builder /go/github.com/vadv/pg_gatherer/bin/pg_gatherer /app/bin/
COPY --from=builder /go/github.com/vadv/pg_gatherer/plugins /app/plugins