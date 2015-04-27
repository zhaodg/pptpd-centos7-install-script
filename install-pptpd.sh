#
#  install-pptpd.sh
#
#  Created by zhaodg on 15-04-26.
#  Copyright (c) 2014年 zhaodg. All rights reserved.
#

#!/bin/bash

# clean
yum -y remove pptpd ppp

iptables --flush POSTROUTING --table nat
iptables --flush FORWARD

rm -rf /etc/pptpd.conf
rm -rf /etc/ppp
rm -rf /dev/ppp

# install component
yum install make openssl gcc-c++ ppp iptables pptpd iptables-services

# /etc/ppp/chap-secrets
pass=`openssl rand 6 -base64`
if [ "$1" != "" ]
  then pass=$1
fi
echo "zhaodg pptpd ${pass} *" >> /etc/ppp/chap-secrets

# /etc/pptpd.conf
echo "localip 192.168.0.1" >> /etc/pptpd.conf
echo "remoteip 192.168.0.234-238,192.168.0.245" >> /etc/pptpd.conf

# /etc/ppp/options.pptpd
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

# /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p # 使内核转发生效

#
iptables -A FORWARD -p tcp --syn -s 192.168.0.0/24 -j TCPMSS --set-mss 1356
#iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig | grep 'inet' | grep 'netmask' | grep 'broadcast' | grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 {print $2}'`
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
/usr/libexec/iptables/iptables.init save

mknod /dev/ppp c 108 0
chmod +x /etc/rc.d/rc.local
echo "1" > /proc/sys/net/ipv4/ip_forward
echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
echo "echo \"1\">/proc/sys/net/ipv4/ip_forward" >> /etc/rc.local

echo "iptables -A INPUT -p tcp  --dport 1723 -j ACCEPT" >> /etc/rc.local
echo "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT" >> /etc/rc.local
echo "iptables -A INPUT -p gre -j ACCEPT" >> /etc/rc.local
echo "iptables -A OUTPUT  -p gre -j ACCEPT" >> /etc/rc.local

echo "iptables -A FORWARD -p tcp --syn -s 192.168.0.0/24 -j TCPMSS --set-mss 1356" >> /etc/rc.local
echo "iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE" >> /etc/rc.local

systemctl restart iptables
systemctl restart pptpd

iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE

# 开机自动启动
chkconfig pptpd on


echo "VPN service is installed, your VPN username is zhaodg, VPN password is ${pass}"