#!/bin/bash -e

source ./configure.sh

./initGCloud.sh

./removeBaseInstance.sh

gcloud compute instances create ${instanceName} --zone=${zone} --machine-type=${machineType} --image=ubuntu-minimal-1810-cosmic-v20190108 --image-project=ubuntu-os-cloud --boot-disk-type=pd-standard --boot-disk-size=10GB --boot-disk-device-name=${instanceName}

./addPublicKeyGoogleCloud.sh ${instanceName}

sleep 5

./installGuidanceDependenciesGoogle.sh

./installCOMPSsGoogle.sh
