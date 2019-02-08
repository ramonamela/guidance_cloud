#!/bin/bash

if gcloud compute disks list --filter=zone:${2} | grep -q ${1}; then
    gcloud compute disks delete ${1} -q --zone=${2}
fi
