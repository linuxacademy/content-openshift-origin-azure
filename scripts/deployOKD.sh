#!/bin/bash

#yum -y update
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion httpd-tools
yum -y install epel-release
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible openssl-devel python-devel
yum -y install openshift-ansible
yum -y install docker

systemctl enable docker-cleanup
systemctl enable docker

cat <<EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=azureuser
ansible_become=yes
debug_level=2
deployment_type=origin
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_cluster_method=native
openshift_master_cluster_hostname=okd.masterVM.xip.io
openshift_master_cluster_public_hostname=okd.masterVM.xip.io

openshift_master_default_subdomain=apps.okd.infraVM.xip.io
openshift_use_dnsmasq=False

openshift_disable_check=disk_availability,memory_availability

[masters]
masterVM.xip.io

[etcd]
masterVM.xip.io

[nodes]
masterVM.xip.io
nodeVM.xip.io openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
infraVM.xip.io openshift_node_labels="{'region': 'infra', 'zone': 'default'}"
EOF

ansible-playbook /usr/share/ansible/openshift-ansible/playbook/prerequisites.yml
ansible-playbook /usr/share/ansible/openshift-ansible/playbook/deploy_cluster.yml
