FROM centos:7

RUN yum install -y epel-release && \
    yum install -y golang && \
    yum install -y @"Development tools" && \
    yum install -y sudo && \
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum install -y postgresql11-server && \
    yum install -y postgresql11-contrib && \
    yum clean all

ENV GO111MODULE=on
ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /opt/pg_gatherer/

# download go modules
COPY go.mod .
COPY go.sum .
RUN go mod download

# copy project
COPY . .