#!/bin/sh

exec 2>&1
set -ex
if [ -n "$GROUP" ] && [ -n "$GROUP_ID" ] && [ "$GROUP_ID" != "$(id -g "$GROUP")" ]; then
    groupmod --gid "$GROUP_ID" "$GROUP"
    chgrp "$GROUP_ID" "$HOME"
fi
if [ -n "$USER" ] && [ -n "$USER_ID" ] && [ "$USER_ID" != "$(id -u "$USER")" ]; then
    usermod --uid "$USER_ID" "$USER"
    chown "$USER_ID" "$HOME"
fi
exec "$@"
