#!/bin/sh
# PID 1 of the workspace (under tini). On first start it seeds the empty
# /home/dev (the PVC) with defaults, then just keeps the container alive:
# ContainerSSH execs sessions into it.
set -eu

H=/home/dev
if [ ! -e "$H/.ws-initialized" ]; then
  cp -r --update=none /etc/skel/. "$H"/
  touch "$H/.ws-initialized"
fi

exec sleep infinity
