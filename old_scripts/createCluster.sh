#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${currentDir}/configure.sh

#${currentDir}/removeCluster.sh

${currentDir}/createBaseInstance.sh

${currentDir}/stopInstance.sh

${currentDir}/createSnapshot.sh

#serviceAccount=$(gcloud compute instances describe ${instanceName} | grep service | awk '{ print $3 }')
#machineType=$(gcloud compute instances describe ${instanceName} | grep machine | awk '{ print $2 }' | tr "/" "\t" | awk '{ print $NF }')

${currentDir}/createCluster.py

#for ((i=1;i<=amountOfNodes;++i)); do
#    ${currentDir}/createClusterNode.sh "${i}"
    #${currentDir}/removeDisk.sh ${currentName}
    #gcloud compute disks create ${currentName} --source-snapshot "${snapName}"
    #gcloud compute instances create "${currentName}" --metadata-from-file startup-script=mountDisk.sh --machine-type ${machineType} --service-account ${serviceAccount} --disk "name=${currentName},device-name=${currentName},mode=rw,boot=yes,auto-delete=yes" --scopes="storage-full"
    #./addPublicKeyGoogleCloud.sh ${currentName}
#done

