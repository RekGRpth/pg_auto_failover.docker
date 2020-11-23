#!/bin/sh -ex

#docker build --tag rekgrpth/pg_auto_failover .
#docker push rekgrpth/pg_auto_failover
#docker pull rekgrpth/pg_auto_failover
docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
docker volume create pg_auto_failover3
docker stop pg_auto_failover3 || echo $?
docker rm pg_auto_failover3 || echo $?
docker run \
    --detach \
    --env CLUSTER_NAME=test \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PG_AUTOCTL_AUTH=trust \
    --env PG_AUTOCTL_MONITOR=postgres://autoctl_node@pg_auto_failover0/pg_auto_failover?sslmode=prefer \
    --env PG_AUTOCTL_NAME=pg_auto_failover3 \
    --env PG_AUTOCTL_REPLICATION_QUORUM=false \
    --env PG_AUTOCTL_SERVER_CERT=/etc/certs/cert.pem \
    --env PG_AUTOCTL_SERVER_KEY=/etc/certs/key.pem \
    --env PG_AUTOCTL_SSL_CA_FILE=/etc/certs/ca.pem \
    --env PG_AUTOCTL_SSL_MODE=prefer \
    --env PG_AUTOCTL=true \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_auto_failover3 \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_auto_failover3,destination=/var/lib/postgresql \
    --name pg_auto_failover3 \
    --network name=docker \
    --restart always \
    rekgrpth/pg_auto_failover runsvdir /etc/service
