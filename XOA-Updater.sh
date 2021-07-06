#!/bin/bash
# xo-updater (early version)
NODEVER="v14.17.3"

curl -L -s -o /tmp/node-${NODEVER}-linux-x64.tar.gz https://nodejs.org/dist/latest-v14.x/node-${NODEVER}-linux-x64.tar.gz
tar -C /tmp -xzf /tmp/node-${NODEVER}-linux-x64.tar.gz
CURD=`pwd`
cd /tmp/node-${NODEVER}-linux-x64
rsync -a bin include lib share /usr/local/
cd ${CURD}


npm update yarn --global

find /opt/xen-orchestra -iname \*.rej -o -iname \*.orig -exec rm {} \;

cd /opt/xen-orchestra
# cleanup last changes
git checkout .
for CHANGED in $(for FILE in $(cat series) ; do head -n2 $FILE ; done |grep -v orig | awk '{print $2}'|sort -u) ; do
	git restore $CHANGED
done
git pull
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
systemctl stop xo-server
/bin/cat << EOF >> /etc/systemd/system/xo-server.service
# Systemd service for XO-Server.

[Unit]
Description= XO Server
After=network-online.target

[Service]
WorkingDirectory=/opt/xen-orchestra/packages/xo-server/
ExecStart=/usr/local/bin/node ./dist/cli.mjs
Restart=always
SyslogIdentifier=xo-server

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start xo-server
r

