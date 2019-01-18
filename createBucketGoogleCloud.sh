#!/bin/bash

## https://cloud.google.com/storage/docs/creating-buckets ##

source ./configure.sh
echo "${bucketProjectName}"
echo "${storageClass}"
echo "${bucketLocation}"
echo "gs://${bucketName}/"
gsutil mb -p "${bucketProjectName}" -c "${storageClass}" -l "${bucketLocation}" "gs://${bucketName}/"

## sudo apt-get install google-cloud-sdk
