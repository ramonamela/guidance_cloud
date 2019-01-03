#!/bin/bash

## CONFIGURE SSH KEYS INTO THE NEW INSTANCE ##

#gcloud init
source ./configure.sh
gcloud compute instances stop ${instanceName}
gcloud compute instances describe ${instanceName} | grep ssh-rsa | xargs -i echo {} > /tmp/publicKeys.txt
currentUsername="$(cat ${publicSSHfile} | awk '{ print $3 }')" && currentPublicKey="$(cat ${publicSSHfile})" && echo "${instanceUsername}:${currentPublicKey}" >> /tmp/publicKeys.txt
gcloud compute instances add-metadata ${instanceName} --metadata-from-file ssh-keys=/tmp/publicKeys.txt
gcloud compute instances start ${instanceName}
rm /tmp/publicKeys.txt
currentIP=$(gcloud compute instances list --filter="${instanceName}" | tail -n1 | awk '{print $5}')
echo $currentIP
