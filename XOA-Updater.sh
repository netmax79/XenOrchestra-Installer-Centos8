#!/bin/bash
# xo-updater (early version)

curl -L -s -o /tmp/node-v14.16.0-linux-x64.tar.gz https://nodejs.org/dist/latest-v14.x/node-v14.16.0-linux-x64.tar.gz
tar -C /tmp -xzf /tmp/node-v14.16.0-linux-x64.tar.gz
CURD=`pwd`
cd /tmp/node-v14.16.0-linux-x64
rsync -a bin include lib share /usr/local/
cd ${CURD}
npm update yarn --global

cd /opt/xen-orchestra
git pull -r --autostash
/usr/local/bin/yarn

curl -s -L -o /root/series https://raw.githubusercontent.com/netmax79/XenOrchestra-Installer-Centos8/master/patches/series
for PATCH in $(cat /root/series) ; do
 curl -s -L -o /root/${PATCH} https://raw.githubusercontent.com/netmax79/XenOrchestra-Installer-Centos8/master/patches/${PATCH}
done

GRC=0
for PATCH in $(cat /root/series) ; do
 echo "Patch: ${PATCH}"
 patch -p1 < /root/${PATCH}
 RC=$?
 GRC=$(expr $GRC + $RC)
done
if [ "$GRC" -gt 0 ] ; then
        echo "Patches not fully applied, error combined error code is: $GRC"
        exit 1
fi

/usr/local/bin/yarn build
systemctl restart xo-server

