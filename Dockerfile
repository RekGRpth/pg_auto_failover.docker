FROM alpine
RUN exec 2>&1 \
    && set -ex \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone --recursive https://github.com/RekGRpth/pg_auto_failover.git \
    && cd /usr/src/pg_auto_failover \
    && make -j"$(nproc)" USE_PGXS=1 install \
    && apk add --no-cache --virtual .postgresql-rundeps \
        musl-locales \
        postgresql \
        postgresql-contrib \
        runit \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/lib/postgresql/pgautofailover.so | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }') \
    && apk del --no-cache .build-deps \
    && rm -rf /usr/src /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man \
    && echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "runsvdir", "/etc/service" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV HOME=/var/lib/postgresql
ENV GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN exec 2>&1 \
    && set -ex \
    && chmod -R 0755 /etc/service /usr/local/bin \
    && echo done
