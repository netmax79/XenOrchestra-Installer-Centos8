#!/bin/bash
# xo-updater (early version)

cd /opt/xen-orchestra
git pull -r --autostash
/usr/local/bin/yarn
/usr/local/bin/yarn build
systemctl restart xo-server

