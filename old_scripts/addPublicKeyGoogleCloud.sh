#!/bin/bash

## CONFIGURE SSH KEYS INTO THE NEW INSTANCE ##

currentInstanceName=$1
currentZone=$2

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#gcloud init
source ${currentDir}/configure.sh
gcloud compute instances stop ${currentInstanceName} --zone=${currentZone}
gcloud compute instances describe ${currentInstanceName} --zone=${currentZone} | grep ssh-rsa | xargs -i echo {} > "/tmp/publicKeys${currentInstanceName}.txt"
currentUsername="$(cat ${publicSSHfile} | awk '{ print $3 }')" && currentPublicKey="$(cat ${publicSSHfile})" && echo "${instanceUsername}:${currentPublicKey}" >> "/tmp/publicKeys${currentInstanceName}.txt"
gcloud compute instances add-metadata ${currentInstanceName} --metadata-from-file ssh-keys="/tmp/publicKeys${currentInstanceName}.txt" --zone=${currentZone}
gcloud compute instances start ${currentInstanceName} --zone=${currentZone}
rm "/tmp/publicKeys${currentInstanceName}.txt"
currentIP=$(gcloud compute instances list --filter="${currentInstanceName}" | tail -n1 | awk '{print $5}')
echo $currentIP
