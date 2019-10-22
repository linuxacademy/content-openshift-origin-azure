#!/bin/bash

echo $(date) " - Starting Script"

# Update system to latest packages and install dependencies
echo $(date) " - Update system to latest packages and install dependencies"

yum -y update
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct httpd-tools

echo $(date) " - System updates successfully installed"

echo $(date) " - Changing interface setting to NM_CONTROLLED=yes "

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=yes
PERSISTENT_DHCLIENT=yes
DHCP_HOSTNAME=bastionVM-0
EOF

systemctl restart network

echo $(date) " - Changed interface setting to NM_CONTROLLED=yes "

echo $(date) " - Adding entries to host file"

echo "10.10.1.13 bastionVM-0 bastion.example.xip.io" >> /etc/hosts
echo "10.10.1.10 masterVM-0  master.example.xip.io   okd.master.example.xip.io" >> /etc/hosts
echo "10.10.1.11 infraVM-0   infra.example.xip.io    apps.okd.infra.example.xip.io" >> /etc/hosts
echo "10.10.1.12 appnodeVM-0 node.example.xip.io" >> /etc/hosts

echo $(date) " - Entries added to host file"

echo $(date) " - Adding SSH keys"

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa -P /home/azureuser/.ssh/

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa.pub -P /home/azureuser/.ssh/

chown -R azureuser:azureuser /home/azureuser/.ssh/id_rsa*
chmod 600 /home/azureuser/.ssh/id_rsa*

ssh -o StrictHostKeyChecking=no master.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no infra.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no node.example.xip.io uname -a

echo $(date) " - SSH keys added"

# Install EPEL repository
echo $(date) " - Installing EPEL"

yum -y install epel-release
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

echo $(date) " - EPEL successfully installed"

# Installation Ansible, pyOpenSSL and python-passlib
echo $(date) " - Installing Ansible, pyOpenSSL and python-passlib"

yum -y --enablerepo=epel install centos-release-ansible26 openssl-devel python-devel

echo $(date) " - Ansible, pyOpenSSL and python-passlib successfully installed"

echo $(date) " - Script Complete"
