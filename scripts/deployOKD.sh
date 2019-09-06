#!/bin/bash

echo $(date) " - Starting Script"

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

# Creating Inventory file
echo $(date) " - Creating Inventory file"

cat <<EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=azureuser
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

# metrics
openshift_metrics_install_metrics=false
openshift_metrics_cassandra_storage_type=dynamic
openshift_metrics_storage_volume_size=20Gi
openshift_metrics_hawkular_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_cassandra_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_heapster_nodeselector={"node-role.kubernetes.io/infra": "true"}

# logging
openshift_logging_install_logging=false
openshift_logging_es_pvc_dynamic=true
openshift_logging_storage_volume_size=10Gi
openshift_logging_kibana_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_curator_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_es_nodeselector={"node-role.kubernetes.io/infra": "true"}

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

#Running OpenShift installation playbooks
echo $(date) " - Running OpenShift installation playbooks"

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

echo $(date) " - OpenShift installation playbooks ran successfully"

echo $(date) " - Script Complete"
