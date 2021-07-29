FROM alpine
ENV HOME=/var/lib/postgresql
RUN set -eux; \
    apk update --no-cache; \
    apk upgrade --no-cache; \
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
    mkdir -p "${HOME}/src"; \
    cd "${HOME}/src"; \
    git clone -b master https://github.com/RekGRpth/pg_auto_failover.git; \
    git clone -b master https://github.com/RekGRpth/pgsidekick.git; \
    git clone -b REL_13_STABLE https://github.com/RekGRpth/pg_rman.git; \
    cd "${HOME}/src/pg_auto_failover"; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd "${HOME}/src/pg_rman"; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd "${HOME}/src/pgsidekick"; \
    make -j"$(nproc)" pglisten; \
    cp -f pglisten /usr/local/bin/; \
    cp -f /usr/bin/pg_config /usr/local/bin/; \
    cd /; \
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
    find /usr/local/bin -type f -exec strip '{}' \;; \
    find /usr/local/lib /usr/lib/postgresql -type f -name "*.so" -exec strip '{}' \;; \
    apk del --no-cache .build-deps; \
    mv -f /usr/local/bin/pg_config /usr/bin/; \
    find /usr -type f -name "*.a" -delete; \
    find /usr -type f -name "*.la" -delete; \
    rm -rf "${HOME}" /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV BACKUP_PATH="${HOME}/pg_rman" \
    GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
