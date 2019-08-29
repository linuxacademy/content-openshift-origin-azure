#!/bin/bash

echo $(date) " - Starting Script"

# Install EPEL repository
echo $(date) " - Installing EPEL"

yum -y install epel-release
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

echo $(date) " - EPEL successfully installed"

# Update system to latest packages and install dependencies
echo $(date) " - Update system to latest packages and install dependencies"

yum -y update
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct httpd-tools

echo $(date) " - System updates successfully installed"

echo $(date) " - Installing Ansible, pyOpenSSL and python-passlib"

yum -y --enablerepo=epel install ansible openssl-devel python-devel

echo $(date) " - Ansible, pyOpenSSL and python-passlib successfully installed"

echo $(date) " - Installing OKD packages, openshift-ansible, and docker"

yum -y install centos-release-openshift-origin39
yum -y install openshift-ansible
yum -y install docker

echo $(date) " -  OKD packages, openshift-ansible, and dockersuccessfully installed"

echo $(date) " - Enabling and starting docker"

sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 104.209.0.0/16'#" /etc/sysconfig/docker
systemctl enable docker-cleanup
systemctl enable docker
systemctl start docker

echo $(date) " - Docker started successfully"

cat <<EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=azureuser
ansible_become=yes
debug_level=2
openshift_deployment_type=origin

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_cluster_method=native
openshift_master_cluster_hostname=okd.masterVM-0.xip.io
openshift_master_cluster_public_hostname=okd.masterVM-0.xip.io

openshift_master_default_subdomain=apps.okd.infraVM-0.xip.io
openshift_use_dnsmasq=True

openshift_disable_check=disk_availability,memory_availability

[masters]
masterVM-0

[etcd]
masterVM-0

[nodes]
masterVM-0
appnodeVM-0 openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
infraVM-0 openshift_node_labels="{'region': 'infra', 'zone': 'default'}"
EOF

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

echo $(date) " - Script Complete"
