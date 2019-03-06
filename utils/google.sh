#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable                                                                                                                                                                                                     
#set -x # Enable bash trace


#
# HELPER METHODS
#


#
# Inits the GCloud session
#
initSession() {
  local identification_json=${1}
  gcloud auth activate-service-account --key-file="${identification_json}"
}


#
# Sets the GCloud project name
#
setProjectName() {
  local project_name=${1}

  gcloud config set project "${project_name}"
}


#
# Sets the GCloud project properties
#
setProjectProperties() {
  local bucket_location=${1}

  local avail_zone
  avail_zone=$(gcloud compute zones list | grep "${bucket_location}" | grep UP | awk '{ print $1 }' | head -n1)
  gcloud config set compute/zone "${avail_zone}"
}


#
# Echoes the bucket location
#
getBucketLocation() {
  local bucket_name=${1}

  local bucket_location
  bucket_location=$(gsutil ls -L -b gs://"${bucket_name}" | grep Location | awk '{ print tolower($3) }')
  echo "${bucket_location}"
}


#
# Echoes the bucket zone
#
getBucketZone() {
  local bucket_name=${1}

  local bucket_zone
  bucket_zone=$(gcloud compute zones list | grep -e "$(gsutil ls -L -b gs://"${bucket_name}" | grep Location | awk '{ print tolower($3) }' )" | awk '{ print $1 }' | sort | head -n1)
  echo "${bucket_zone}"
}


#
# Checks if an instance exists. Echoes 0 if it exists, 1 otherwise
#
checkInstanceExistance() {
  local instance_name=${1}

  gcloud compute instances list | grep -q "${instance_name}"
  echo "$?"
}


#
# Echoes the instance zone
#
getInstanceZone() {
  local instance_name=${1}

  local instance_zone
  instance_zone=$(gcloud compute instances list | grep "${instance_name}" | awk '{ print $2 }')
  echo "${instance_zone}"
}


#
# Removes the given instance
#
removeInstance() {
  local instance_name=${1}

  local ie
  ie=$(checkInstanceExistance "${instance_name}")
  if [ "0" -eq "${ie}" ]; then
    local instance_zone
    instance_zone=$(getInstanceZone "${instance_name}")
    gcloud compute instances delete "${instance_name}" -q --zone="${instance_zone}"
  fi
}


#
# Echoes the service account
#
getServiceAccount() {
  local identification_json=${1}

  local service_acc
  service_acc=$(grep "client_email" "${identification_json}" | awk '{ print $2 }' | sed 's/\"//g' | sed 's/,//g')

  echo "${service_acc}"
}


#
# Adds a public key to an instance
#
addPublicKey() {
  local current_instance_name=${1}
  local current_zone=${2}
  local public_ssh_file=${3}
  local instance_username=${4}
  
  local pubkey_path="/tmp/publicKeys${current_instance_name}.txt"
  local current_public_key
  
  gcloud compute instances stop "${current_instance_name}" --zone="${current_zone}"
  gcloud compute instances describe "${current_instance_name}" --zone="${current_zone}" | grep ssh-rsa | xargs -i echo {} > "${pubkey_path}"
  current_public_key=$(cat "${public_ssh_file}")
  echo "${instance_username}:${current_public_key}" >> "${pubkey_path}"
  gcloud compute instances add-metadata "${current_instance_name}" --metadata-from-file ssh-keys="${pubkey_path}" --zone="${current_zone}"
  gcloud compute instances start "${current_instance_name}" --zone="${current_zone}"
  rm "${pubkey_path}"
}


#
# Put into CURRENT_IP the instance IP (so this can be used to get the IP of an instance assuming it is running)
#
waitUntilRunning() {
  local instance_name=${1}
  local instance_username=${2}
  
  CURRENT_IP=$(gcloud compute instances list --filter="${instance_name}" | tail -n1 | awk '{print $5}')
  while ! ssh -q -o "StrictHostKeyChecking no" "${instance_username}"@"${CURRENT_IP}" "exit"; do
    echo "Could not stablish connection with ${instance_username}@${CURRENT_IP}, retrying..."
    sleep 1s
    CURRENT_IP=$(gcloud compute instances list --filter="${instance_name}" | tail -n1 | awk '{print $5}')
    #ssh -q -o "StrictHostKeyChecking no" "${instance_username}"@"${CURRENT_IP}" "exit" || ev=$? && true
  done
  echo "The image ${instance_username}@${CURRENT_IP} is already running"
}


#
# Creates a base instance
#
createBaseInstance() {
  local instance_name=${1}
  local service_account=${2}
  local project_name=${3}
  local current_zone=${4}
  
  local ubuntu_image="ubuntu-minimal-1810-cosmic-v20190122"
  #local ubuntu_image="ubuntu-minimal-1804-lts"
  
  gcloud compute instances create "${instance_name}" \
    --zone "${current_zone}" \
    --machine-type n1-standard-1 \
    --image "${ubuntu_image}" \
    --image-project ubuntu-os-cloud \
    --boot-disk-type pd-standard \
    --boot-disk-size 10GB \
    --boot-disk-device-name "${instance_name}" \
    --service-account "${service_account}"
}
