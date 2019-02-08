#!/bin/bash

scriptsDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

source "${scriptsDir}/utilsGoogle.sh"
source "${scriptsDir}/configureSnapshot.sh"
source "${scriptsDir}/utils.sh"

createNewBaseInstance(){

    createBaseInstance ${baseInstanceName} ${serviceAccount} ${projectName} ${bucketZone}
    addPublicKey ${baseInstanceName} ${bucketZone} ${publicSSHfile} ${username}
    waitUntilRunning ${baseInstanceName} ${username}

}

main(){

    initSession ${identificationJson} ${projectName} ${bucketLocation}

    bucketLocation=$(getBucketLocation ${bucketName})
    bucketZone=$(getBucketZone ${bucketName})
    serviceAccount=$(getServiceAccount ${identificationJson})

    setProjectProperties ${projectName} ${bucketLocation}

    if [ "${overrideInstance}" = "true" ]; then
        removeInstance ${baseInstanceName}
        ## CREATE INSTANCE
        echo "Create instance"
        createNewBaseInstance
    else
        if [ "0" -eq "$(checkInstanceExistance ${baseInstanceName})" ]; then
            echo "CREATING SNAPSHOT FROM EXISTING INSTANCE"
            echo "Set the configuration 'override' parameter to \"true\" in order to generate the instance again"
        else
            ## CREATE INSTANCE
            echo "Create instance"
            createNewBaseInstance
        fi
    fi

    # This is done in order to mount a FUSE system on the bucket
    # Look into GCSFuse and https://github.com/s3fs-fuse/s3fs-fuse/wiki/Fuse-Over-Amazon
    ssh -q -o "StrictHostKeyChecking no" ${username}@${currentIP} "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"

    installGuidanceDependencies ${username} ${currentIP}

    installCOMPSs ${username} ${currentIP}

}

main


