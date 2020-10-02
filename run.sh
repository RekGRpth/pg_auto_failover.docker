#!/bin/sh -ex

#docker build --tag rekgrpth/pg_auto_failover .
#docker push rekgrpth/pg_auto_failover
#docker pull rekgrpth/pg_auto_failover
docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
docker volume create pg_auto_failover
docker stop pg_auto_failover || echo $?
docker rm pg_auto_failover || echo $?
docker run \
    --detach \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env SERVER_CERT=/etc/certs/cert.pem \
    --env SERVER_KEY=/etc/certs/key.pem \
    --env SSL_CA_FILE=/etc/certs/ca.pem \
    --env SSL_MODE=prefer \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_auto_failover \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_auto_failover,destination=/var/lib/postgresql \
    --name pg_auto_failover \
    --network name=docker \
    --restart always \
    rekgrpth/pg_auto_failover runsvdir /etc/service
