#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${currentDir}/configure.sh

echo "Init google cloud"
${currentDir}/initGCloud.sh

echo "Remove base instance"
${currentDir}/removeBaseInstance.sh

echo "Create new base instance in ${currentZone}"
serviceAccount=$(cat guidance-06986d1d6789.json | grep client_email | awk '{ print $2 }' | sed 's/\"//g' | sed 's/,//g')
echo "gcloud compute instances create ${instanceName} --zone ${currentZone} --machine-type ${machineType} --image ubuntu-minimal-1810-cosmic-v20190108 --image-project ubuntu-os-cloud --boot-disk-type pd-standard --boot-disk-size 10GB --boot-disk-device-name ${instanceName} --service-account ${serviceAccount}"

#gcloud compute instances create ${instanceName} --zone ${currentZone} --machine-type ${machineType} --image ubuntu-minimal-1810-cosmic-v20190108 --image-project ubuntu-os-cloud --boot-disk-type pd-standard --boot-disk-size 10GB --boot-disk-device-name ${instanceName} --service-account ${serviceAccount}
gcloud compute instances create ${instanceName} --zone ${currentZone} --machine-type n1-standard-1 --image ubuntu-minimal-1810-cosmic-v20190108 --image-project ubuntu-os-cloud --boot-disk-type pd-standard --boot-disk-size 10GB --boot-disk-device-name ${instanceName} --service-account ${serviceAccount}

echo "Add public key google cloud"
${currentDir}/addPublicKeyGoogleCloud.sh ${instanceName}

echo "Wait until the image is running"
currentIP=$(gcloud compute instances list --filter="${instanceName}" | tail -n1 | awk '{print $5}')
ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "exit"
while [ ! "$?" -eq "0" ]; do
    echo "Could not stablish connection, retry"
    sleep 1
    currentIP=$(gcloud compute instances list --filter="${instanceName}" | tail -n1 | awk '{print $5}')
    ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "exit"
done

echo "The image is already running"
## Create and mount bucket
#${currentDir}/createBucketGoogleCloud.sh

ssh -q -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"

#ssh -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "mkdir -p \$HOME/${bucketName}"
#scp -o "StrictHostKeyChecking no" installGFuse.sh ${instanceUsername}@${currentIP}:\$HOME
#ssh -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "sh \$HOME/installGFuse.sh"
#ssh -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "rm -f \$HOME/installGFuse.sh"
#ssh -o "StrictHostKeyChecking no" ${instanceUsername}@${currentIP} "gcsfuse bucket-guidance \$HOME/${bucketName}"

echo "Install guidance dependencies"
${currentDir}/installGuidanceDependenciesGoogle.sh

echo "Install compss"
${currentDir}/installCOMPSsGoogle.sh
