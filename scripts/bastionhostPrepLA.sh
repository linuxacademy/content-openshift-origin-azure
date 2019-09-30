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

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa -P /home/cloud_user/.ssh/

wget https://raw.githubusercontent.com/linuxacademy/content-openshift-origin-azure/master/ssh/id_rsa.pub -P /home/cloud_user/.ssh/

chown cloud_user:cloud_user /home/cloud_user/.ssh/id_rsa*
chmod 600 /home/cloud_user/.ssh/id_rsa*

ssh -o StrictHostKeyChecking=no master.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no infra.example.xip.io uname -a

ssh -o StrictHostKeyChecking=no @node.example.xip.io uname -a

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

echo $(date) " - Installing OKD packages, openshift-ansible, and docker"

yum -y install centos-release-openshift-origin
yum -y install openshift-ansible
yum -y install docker
sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker

echo $(date) " -  OKD packages, openshift-ansible, and dockersuccessfully installed"

# Enabling Docker
echo $(date) " - Enabling and starting docker"

systemctl enable docker-cleanup
systemctl enable docker
systemctl start docker

echo $(date) " - Docker started successfully"

chmod -R 777 /usr/share/ansible/openshift-ansible/playbooks

# Creating Inventory file
echo $(date) " - Creating Inventory file"

cat <<EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=cloud_user
ansible_become=yes
debug_level=2
openshift_deployment_type=origin

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]

openshift_master_cluster_method=native
openshift_master_cluster_hostname=okd.master.example.xip.io
openshift_master_cluster_public_hostname=okd.master.example.xip.io
openshift_master_default_subdomain=apps.okd.infra.example.xip.io
openshift_use_dnsmasq=True

openshift_disable_check=disk_availability,memory_availability

[masters]
master.example.xip.io

[etcd]
master.example.xip.io

[nodes]
master.example.xip.io openshift_node_group_name='node-config-master'
node.example.xip.io openshift_node_group_name='node-config-compute'
infra.example.xip.io openshift_node_group_name='node-config-infra'
EOF

echo $(date) " - Inventory file created"

echo $(date) " - Script Complete"
