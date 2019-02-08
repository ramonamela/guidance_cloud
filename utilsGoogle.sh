initSession(){

    local identificationJson=${1}

    gcloud auth activate-service-account --key-file=${identificationJson}
}

setProjectProperties(){

    local projectName=${1}
    local bucketLocation=${2}

    gcloud config set project ${projectName}
    local availZone=$(gcloud compute zones list | grep ${bucketLocation} | grep UP | awk '{print $1 }' | head -n1)
    gcloud config set compute/zone ${availZone}
}

getBucketLocation(){

    local bucketName=${1}

    local bucketLocation=$(gsutil ls -L -b gs://${bucketName} | grep Location | awk '{ print tolower($3) }')

    echo ${bucketLocation}
}

getBucketZone(){

    local bucketName=${1}

    local bucketZone=$(gcloud compute zones list | grep -e $(gsutil ls -L -b gs://${bucketName} | grep Location | awk '{ print tolower($3) }' ) | awk '{ print $1 }' | sort | head -n1)

    echo ${bucketZone}
}

## 0 exists
## 1 does not exist
checkInstanceExistance(){

    local instance_name=${1}

    gcloud compute instances list | grep -q ${instance_name}
    echo $?
}

getInstanceZone(){

    local instance_name=${1}

    echo $(gcloud compute instances list | grep ${instance_name} | awk '{ print $2 }')

}

removeInstance(){

    local instance_name=${1}

    if [ "0" -eq $(checkInstanceExistance ${instance_name}) ]; then
        local instanceZone=$(getInstanceZone ${instance_name})
        gcloud compute instances delete ${instance_name} -q --zone=${instanceZone}
    fi
}

getServiceAccount(){

    local identificationJson=${1}

    echo $(cat ${identificationJson} | grep client_email | awk '{ print $2 }' | sed 's/\"//g' | sed 's/,//g')

}

addPublicKey(){

    local currentInstanceName=${1}
    local currentZone=${2}
    local publicSSHfile=${3}
    local instance_username=${4}

    gcloud compute instances stop ${currentInstanceName} --zone=${currentZone}
    gcloud compute instances describe ${currentInstanceName} --zone=${currentZone} | grep ssh-rsa | xargs -i echo {} > "/tmp/publicKeys${currentInstanceName}.txt"
    currentPublicKey="$(cat ${publicSSHfile})" && echo "${instance_username}:${currentPublicKey}" >> "/tmp/publicKeys${currentInstanceName}.txt"
    gcloud compute instances add-metadata ${currentInstanceName} --metadata-from-file ssh-keys="/tmp/publicKeys${currentInstanceName}.txt" --zone=${currentZone}
    gcloud compute instances start ${currentInstanceName} --zone=${currentZone}
    rm "/tmp/publicKeys${currentInstanceName}.txt"

}

# Put into currentIP the instance IP (so this can be used to get the IP of an instance assuming it is running)
waitUntilRunning(){

    local instance_name=${1}
    local instance_username=${2}

    currentIP=$(gcloud compute instances list --filter="${instance_name}" | tail -n1 | awk '{print $5}')
    ssh -q -o "StrictHostKeyChecking no" ${instance_username}@${currentIP} "exit"
    while [ ! "$?" -eq "0" ]; do
        echo "Could not stablish connection with ${instance_username}@${currentIP}, retry"
        sleep 1
        currentIP=$(gcloud compute instances list --filter="${instance_name}" | tail -n1 | awk '{print $5}')
        ssh -q -o "StrictHostKeyChecking no" ${instance_username}@${currentIP} "exit"
    done
    echo "The image ${instance_username}@${currentIP} is already running"

}

createBaseInstance(){

    local instance_name=${1}
    local serviceAccount=${2}
    local projectName=${3}
    local currentZone=${4}

    gcloud compute instances create ${instance_name} --zone ${currentZone} --machine-type n1-standard-1 --image ubuntu-minimal-1810-cosmic-v20190122 --image-project ubuntu-os-cloud --boot-disk-type pd-standard --boot-disk-size 10GB --boot-disk-device-name ${instance_name} --service-account ${serviceAccount}

}
