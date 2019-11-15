#!/bin/bash
##
red=$(tput setaf 1)
green=$(tput setaf 2)
orange=$(tput setaf 3)
echo "${green}######################################"
echo "${green}Please run this scripts on SU"
echo "######################################"
hostnamectl set-hostname XOA
echo "${green}==================================="
echo "${green}Working...."
echo "${green}Please wait.."
echo "${green}==================================="
yum install epel-release haveged -y > /dev/null 2>&1
systemctl enable haveged
systemctl start haveged
# install ssl
echo "${green}==================================="
echo "Install Open SSL.."
echo "${green}==================================="
yum install mod_ssl -y > /dev/null 2>&1
# add repo node js
echo "${red}==================================="
echo "add repo nodeJS v8.xx..."
echo "${red}==================================="
#curl -s -L https://rpm.nodesource.com/setup_10.x | bash - > /dev/null 2>&1
curl -s -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo > /dev/null 2>&1
# Node
echo "${red}==================================="
echo "install nodeJS...."
echo "Please wait......"
echo "${red}==================================="
sleep 1
yum install nodejs -y  > /dev/null 2>&1
# install yarn package
echo "${green}==================================="
echo "Install yarn package...."
echo "${green}==================================="
sleep 2
yum install yarn -y > /dev/null 2>&1
# install lib vhd tools
sleep 1
echo "${red}==================================="
echo "Install vhd tools...."
echo "${red}==================================="
rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el8.rpm > /dev/null 2>&1
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cert-forensics-tools.repo > /dev/null 2>&1
yum --enablerepo=forensics install -y libvhdi-tools > /dev/null 2>&1
# install kebutuhan xoa
echo "${green}==================================="
echo "Install build tools 4 xoa..."
echo "${green}==================================="
sleep 1
yum install gcc gcc-c++ make openssl-devel patch redis libpng-devel python git nfs-utils -y > /dev/null 2>&1
# enable service redis  dll 
echo "${orange}==================================="
echo "enable redis server..."
echo "${green}==================================="
/bin/systemctl enable redis && /bin/systemctl start redis
/bin/systemctl enable rpcbind && /bin/systemctl start rpcbind 
echo "${orange}==================================="
echo " clone xoa engine from source"
echo "${orange}==================================="
sleep 1
cd /opt/
/usr/bin/git clone https://github.com/vatesfr/xen-orchestra 
# allow config restoreee
sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
echo "${orange}==================================="
echo "Build your XOA ... (in 10 seconds)"
echo "${green}==================================="
sleep 10
echo "${orange}==================================="
echo "3 ..."
echo "${green}==================================="
echo "${orange}==================================="
echo "2 ..."
echo "${green}==================================="
echo "${orange}==================================="
echo "1 ..."
echo "${green}==================================="
echo "Downloading patches ..."
echo "${green}==================================="
cd /opt/xen-orchestra
curl -s -L -o /root/series https://raw.githubusercontent.com/netmax79/XenOrchestra-Installer-Centos8/master/patches/series
for PATCH in $(cat /root/series) ; do
 curl -s -L -o /root/${PATCH} https://raw.githubusercontent.com/netmax79/XenOrchestra-Installer-Centos8/master/patches/${PATCH}
done
echo "${orange}==================================="
echo "Running yarn ..."
echo "${orange}==================================="
/usr/bin/yarn
echo "${green}==================================="
echo "Applying patches ..."
echo "${orange}==================================="
for PATCH in $(cat /root/series) ; do
 patch -p1 < /root/${PATCH}
done
echo "${orange}==================================="
echo "Running yarn build ..."
echo "${orange}==================================="
/usr/bin/yarn build
# configure xoa
echo "${green}==================================="
echo "----------AUTO configure xoa----------"
echo "${orange}==================================="
sleep 5
cd /opt/xen-orchestra/packages/xo-server
\cp sample.config.toml .xo-server.toml
chmod a+x /opt/xen-orchestra/packages/xo-server/.xo-server.toml
sed -i "s|#'/' = '/path/to/xo-web/dist/'|'/' = '../xo-web/dist/'|" .xo-server.toml
sed -i "s|port = 80|#port = 80|" .xo-server.toml
sed -i "s|# port = 443|port = 443|" .xo-server.toml
# certificate name design auto generate after install xo.
sed -i "s|# cert = './certificate.pem'|cert = '/etc/ssl/cert/cert-selfsigned.pem'|" .xo-server.toml
sed -i "s|# key = './key.pem'|key = '/etc/ssl/cert/key-selfsigned.pem'|" .xo-server.toml
# create node
echo "${orange}==================================="
echo "Create node ..."
echo "${green}==================================="
sleep 5
mkdir -p /usr/local/lib/node_modules/
ln -s /opt/xen-orchestra/packages/xo-server-* /usr/local/lib/node_modules/
rm -rf /etc/systemd/system/xo-server.service
#bikin service daemon xoa
echo "${orange}==================================="
echo "Create XOA daemon service on systemd ....."
echo "${green}==================================="
/bin/cat << EOF >> /etc/systemd/system/xo-server.service
# Systemd service for XO-Server.

[Unit]
Description= XO Server
After=network-online.target

[Service]
WorkingDirectory=/opt/xen-orchestra/packages/xo-server/
ExecStart=/usr/bin/node ./bin/xo-server
Restart=always
SyslogIdentifier=xo-server

[Install]
WantedBy=multi-user.target
EOF

echo "${orange}==================================="
echo "... SELFSIGN-SSL Auto configure for XOA ..."
echo "${green}==================================="
sleep 5
mkdir -p /etc/ssl/cert
echo "${orange}==================================="
echo "Generate self ssl"
echo "${orange}==================================="
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/ssl/cert/key-selfsigned.pem -out /etc/ssl/cert/cert-selfsigned.pem -subj "/C=DE/ST=Bavaria/L=Munich/O=Linux Administrator Networks/OU=IT Department/CN=xoa"
openssl dhparam -out /etc/ssl/cert/dhparam.pem 4096
cat /etc/ssl/cert/dhparam.pem | tee -a /etc/ssl/certs/cert-selfsigned.pem
echo "+++++++++++++++++++++++++++"
echo "========="DONE"============"
echo "+++++++++++++++++++++++++++"
systemctl daemon-reload
systemctl enable xo-server.service
service xo-server start

if [ "`rpm -q firewalld`" == "0" ] ; then
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --reload
#service firewalld stop
#systemctl disable firewalld.service
fi
service xo-server restart 
service xo-server status
node -v 
npm -v
yarn --version
sleep 2
echo "${green}==================================="
echo "done"
echo "${green}==================================="
echo "${orange}==================================="
host=$(hostname -I)
echo "and then acces https://$host"
echo "username : admin@admin.net"
echo "password : admin"
echo "${orange}================================================="
service sshd restart
echo "--------------------------------------------------------------"
