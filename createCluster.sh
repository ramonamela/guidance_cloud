#!/bin/bash

source ./configure.sh

index=3

serviceAccount=$(gcloud compute instances describe ${instanceName} | grep service | awk '{ print $3 }')
machineType=$(gcloud compute instances describe ${instanceName} | grep machine | awk '{ print $2 }' | tr "/" "\t" | awk '{ print $NF }')

#gcloud compute instances delete "${baseInstanceName}${index}" -q
#gcloud compute disks delete "${baseInstanceName}${index}" -q

#gcloud compute disks create "${baseInstanceName}${index}" --source-snapshot "${snapName}" 
#gcloud compute instances create "${baseInstanceName}${index}" --machine-type ${machineType} --service-account ${serviceAccount} --disk "name=${baseInstanceName}${index},device-name=${baseInstanceName}${index},mode=rw,boot=yes,auto-delete=yes"

for ((i=1;i<=index;++i)); do
    currentName="${baseInstanceName}$(printf %04d $i)"
    gcloud compute disks create ${currentName} --source-snapshot "${snapName}"
    echo gcloud compute instances create "${currentName}" --machine-type ${machineType} --service-account ${serviceAccount} --disk "name=${currentName},device-name=${currentName},mode=rw,boot=yes,auto-delete=yes"
    gcloud compute instances create "${currentName}" --machine-type ${machineType} --service-account ${serviceAccount} --disk "name=${currentName},device-name=${currentName},mode=rw,boot=yes,auto-delete=yes"
    ./addPublicKeyGoogleCloud.sh ${currentName}
done

#gcloud compute disks create ${allNames} --source-snapshot "${snapName}" 
#gcloud compute instances create "${baseInstanceName}${index}" --machine-type ${machineType} --service-account ${serviceAccount} --source-instance-template ${instanceName}
