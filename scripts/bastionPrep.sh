#!/bin/bash

echo $(date) " - Starting Script"

# Update system to latest packages and install dependencies
echo $(date) " - Update system to latest packages"

yum -y update

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

echo $(date) " - Changed interface setting to NM_CONTROLLED=yes "

echo $(date) " - Adding entries to host file"

echo "10.10.1.13 bastionVM-0 bastion.example.xip.io" >> /etc/hosts
echo "10.10.1.10 masterVM-0  master.example.xip.io   okd.master.example.xip.io" >> /etc/hosts
echo "10.10.1.11 infraVM-0   infra.example.xip.io    apps.okd.infra.example.xip.io" >> /etc/hosts
echo "10.10.1.12 appnodeVM-0 node.example.xip.io" >> /etc/hosts

echo $(date) " -Entries added to host file"

echo $(date) " - Adding SSH keys"

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa -P /home/azureuser/.ssh/

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa.pub -P /home/azureuser/.ssh/

chown azureuser:azureuser /home/azureuser/.ssh/id_rsa*
chmod 600 /home/azureuser/.ssh/id_rsa*

ssh -o StrictHostKeyChecking=no azureuser@master.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no azureuser@infra.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no azureuser@node.example.xip.io uname -a

echo $(date) " - SSH keys added"

echo $(date) " - Script Complete"
