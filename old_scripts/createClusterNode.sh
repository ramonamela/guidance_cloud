#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${currentDir}/configure.sh

serviceAccount=$(gcloud compute instances describe ${instanceName} | grep service | awk '{ print $3 }')
machineType=$(gcloud compute instances describe ${instanceName} | grep machine | awk '{ print $2 }' | tr "/" "\t" | awk '{ print $NF }')

currentZone="us-east1-c"
currentName="${baseInstanceName}$(printf %04d ${1})"

${currentDir}/removeInstance.sh ${currentName} ${currentZone}
${currentDir}/removeDisk.sh ${currentName} ${currentZone}

gcloud compute disks create ${currentName} --zone=${currentZone} --source-snapshot "${snapName}"
gcloud compute instances create "${currentName}" --zone=${currentZone} --machine-type ${machineType} --service-account ${serviceAccount} --disk "name=${currentName},device-name=${currentName},mode=rw,boot=yes,auto-delete=yes" --scopes="storage-full"
${currentDir}/addPublicKeyGoogleCloud.sh ${currentName} ${currentZone}

echo "Wait until the image is running"
currentIP=$(gcloud compute instances list --filter="${currentName}" --filter=zone:${currentZone} | tail -n1 | awk '{print $5}')
ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "exit"
while [ ! "$?" -eq "0" ]; do
    echo "Could not stablish connection with ${instanceUsername}@${currentIP}, retry"
    sleep 3
    currentIP=$(gcloud compute instances list --filter="${currentName}" --filter=zone:${currentZone} | tail -n1 | awk '{print $5}')
    ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "exit"
done

#ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"

ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "bash -s" -- < ${currentDir}/mountDisk.sh ${bucketName}
while [ ! "$?" -eq "0" ]; do
    sleep 3
    ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "bash -s" -- < ${currentDir}/mountDisk.sh ${bucketName}
done