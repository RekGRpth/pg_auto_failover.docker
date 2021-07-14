FROM alpine
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        readline-dev \
        zlib-dev \
    ; \
    mkdir -p /usr/src; \
    cd /usr/src; \
    git clone --recursive https://github.com/RekGRpth/pg_auto_failover.git; \
    git clone --recursive https://github.com/RekGRpth/pg_rman.git; \
    git clone --recursive https://github.com/RekGRpth/pgsidekick.git; \
    cd /usr/src/pg_auto_failover; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd /usr/src/pg_rman; \
    git checkout REL_13_STABLE; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd /usr/src/pgsidekick; \
    make -j"$(nproc)" pglisten; \
    cp -f pglisten /usr/local/bin/; \
    cp -f /usr/bin/pg_config /usr/local/bin/; \
    apk add --no-cache --virtual .postgresql-rundeps \
        busybox-extras \
        busybox-suid \
        ca-certificates \
        jq \
        musl-locales \
        pgbouncer \
        postgresql \
        postgresql-contrib \
        procps \
        runit \
        sed \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | while read -r lib; do test ! -e "/usr/local/lib/$lib" && echo "so:$lib"; done) \
    ; \
    (strip /usr/local/bin/* /usr/local/lib/*.so || true); \
    apk del --no-cache .build-deps; \
    mv -f /usr/local/bin/pg_config /usr/bin/; \
    rm -rf /usr/src /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    find / -name "*.a" -delete; \
    find / -name "*.la" -delete; \
    echo done
CMD [ "/etc/service/postgres/run" ]
COPY bin /usr/local/bin
COPY service /etc/service
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV HOME=/var/lib/postgresql
ENV BACKUP_PATH=${HOME}/pg_rman \
    GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
