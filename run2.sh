#!/bin/sh -ex

#docker build --tag rekgrpth/pg_auto_failover .
#docker push rekgrpth/pg_auto_failover
#docker pull rekgrpth/pg_auto_failover
docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
docker volume create pg_auto_failover2
docker stop pg_auto_failover2 || echo $?
docker rm pg_auto_failover2 || echo $?
docker run \
    --detach \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PG_AUTO_FAILOVER_MONITOR=postgres://autoctl_node@pg_auto_failover0:5432/pg_auto_failover?sslmode=prefer \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_auto_failover2 \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_auto_failover2,destination=/var/lib/postgresql \
    --name pg_auto_failover2 \
    --network name=docker \
    --restart always \
    rekgrpth/pg_auto_failover