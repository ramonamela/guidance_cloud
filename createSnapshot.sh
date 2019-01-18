#!/bin/bash

source ./configure.sh

## Get disk name
#describeContent=$(gcloud compute instances describe ${instanceName})
diskName=$(gcloud compute instances describe ${instanceName} | grep -A5 disk | grep deviceName | awk '{ print $2 }')

echo $diskName


gcloud compute disks snapshot $diskName --snapshot-names ${snapName}
