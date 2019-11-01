FROM vadv/pg_gatherer:pre-test

ENV GO111MODULE=on
ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /opt/pg_gatherer/

# download go modules
COPY go.mod .
COPY go.sum .
RUN go mod download

# copy project
COPY . .
