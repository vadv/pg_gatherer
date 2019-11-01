FROM centos:7

RUN echo $'[timescale_timescaledb] \n\
name=timescale_timescaledb \n\
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch \n\
repo_gpgcheck=1 \n\
gpgcheck=0 \n\
enabled=1 \n\
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey \n\
sslverify=1 \n\
sslcacert=/etc/pki/tls/certs/ca-bundle.crt \n\
metadata_expire=300' > /etc/yum.repos.d/timescale_timescaledb.repo

RUN yum install -y epel-release && \
    yum install -y golang && \
    yum install -y @"Development tools" && \
    yum install -y sudo && \
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum install -y postgresql11-server && \
    yum install -y postgresql11-contrib && \
    yum install -y timescaledb-postgresql-11 && \
    yum clean all
