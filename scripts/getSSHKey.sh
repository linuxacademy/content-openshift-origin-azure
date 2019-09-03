#!/bin/bash

keyvaultUrl="https://ltajlvault01.vault.azure.net/"
keyvaultSecretName="sshKey"

token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true -s | cut -d',' -f1 | cut -d':' -f2 | sed 's/"//g')
sshKey=$(curl "${keyvaultUrl}/secrets/${keyvaultSecretName}?api-version=2016-10-01" -H "Authorization: Bearer ${token}" -s | cut -d',' -f1 | cut -d':' -f2 | sed 's/"//g')

echo $sshKey
echo ""
echo ""
echo "Saving key to sshKey"
echo ""
echo $sshKey > sshKey
