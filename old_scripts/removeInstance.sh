#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${currentDir}/configure.sh
currentZone=${2}

if gcloud compute instances list | grep -q -w ${1}; then
    gcloud compute instances delete ${1} -q
else
    echo "It does not exist a node with the name ${1}"
fi

