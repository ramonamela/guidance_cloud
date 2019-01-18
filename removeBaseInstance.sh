#!/bin/bash -e

source ./configure.sh

baseInstanceLine=$(gcloud compute instances list --filter="${instanceName}")

if [ ! -z "${baseInstanceLine}" ];
then
    gcloud compute instances delete ${instanceName} -q
fi



