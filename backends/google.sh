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
# Init methods
#

# Initializes the GCloud session
initSession() {
  local identification_json=${1}
  gcloud auth activate-service-account --key-file="${identification_json}"
}

#
# Global properties
#

# Sets the GCloud project name
setProjectName() {
  local project_name
  project_name=$(gcloud auth list 2>&1 | grep "\*" | awk '{ print $2 }' | tr "@" "\t" | awk '{ print $2 }' | sed "s/.iam.gserviceaccount.com//")

  gcloud config set project "${project_name}"
}

# Sets the GCloud project properties
setProjectProperties() {
  local bucket_location=${1}

  local avail_zone
  avail_zone=$(gcloud compute zones list | grep "${bucket_location}" | grep UP | awk '{ print $1 }' | head -n1)
  gcloud config set compute/zone "${avail_zone}"
}

# Echoes the bucket location
getBucketLocation() {
  local bucket_name=${1}

  local bucket_location
  bucket_location=$(gsutil ls -L -b gs://"${bucket_name}" | grep Location | awk '{ print tolower($3) }')
  echo "${bucket_location}"
}

# Echoes the bucket zone
getBucketZone() {
  local bucket_name=${1}

  local bucket_zone
  bucket_zone=$(gcloud compute zones list | grep -e "$(gsutil ls -L -b gs://"${bucket_name}" | grep Location | awk '{ print tolower($3) }' )" | awk '{ print $1 }' | sort | head -n1)
  echo "${bucket_zone}"
}

# Echoes the service account
getServiceAccountFromJSON() {
  local identification_json=${1}

  local service_acc
  service_acc=$(grep "client_email" "${identification_json}" | awk '{ print $2 }' | sed 's/\"//g' | sed 's/,//g')

  echo "${service_acc}"
}

# Echoes the service account
getServiceAccount() {
  local instance_name=${1}

  local service_acc
  service_acc=$(gcloud compute instances describe "${instance_name}" | grep "email" | tr ":" "\\t" | awk '{ print $NF }')

  echo "${service_acc}"
}

# Adds a public key to an instance
addPublicKey() {
  local instance_name=$1
  local zone=$2
  local username=$3
  local public_ssh_file=$4

  local tmp_public_key="/tmp/publicKeys${instance_name}.txt"

  # Retrieve instance public keys
  gcloud compute instances stop "${instance_name}" --zone="${zone}"
  gcloud compute instances describe "${instance_name}" --zone="${zone}" | grep ssh-rsa | xargs -i echo {} > "${tmp_public_key}"

  # Append public keys to file
  current_public_key=$(cat "${public_ssh_file}")
  echo "${username}:${current_public_key}" >> "${tmp_public_key}"

  # Upload new public keys
  gcloud compute instances add-metadata "${instance_name}" \
    --metadata-from-file ssh-keys="${tmp_public_key}" \
    --zone="${zone}"
  gcloud compute instances start "${instance_name}" --zone="${zone}"

  # Clean public key
  rm "${tmp_public_key}"
}


#
# VM IP methods
#

# Waits until the specified VM is running (has SSH access)
waitUntilRunning() {
  local instance_name=$1
  local zone=$2
  local username=$3

  current_ip=$(gcloud compute instances list --filter=zone:"${zone}" | grep "${instance_name}" | awk '{ print $5 }')
  while ! ssh -q -o "StrictHostKeyChecking no" "${username}"@"${current_ip}" "exit"; do
    echo "[INFO] Could not establish connection with ${username}@${current_ip}, retrying..."
    sleep 3s
    current_ip=$(gcloud compute instances list --filter=zone:"${zone}" | grep "${instance_name}" | awk '{ print $5 }')
  done
}

# Echoes the VM IP
getIP() {
  local instance_name=$1
  local zone=$2

  current_ip=$(gcloud compute instances list --filter=zone:"${zone}" | grep "${instance_name}" | awk '{ print $5 }')
  echo "${current_ip}"
}

# Echoes the VM private IP
getPrivateIP() {
  local instance_name=$1
  local zone=$2

  current_ip=$(gcloud compute instances list --filter=zone:"${zone}" | grep "${instance_name}" | awk '{ print $4 }')
  echo "${current_ip}"
}


#
# Disk methods
#

# Creates a new disk instance
createDisk() {
  local instance_name=$1
  local snapshot_name=$2
  local zone=$3

  gcloud compute disks create "${instance_name}" \
    --zone="${zone}" \
    --source-snapshot "${snapshot_name}"
}

# Removes a disk instance
removeDisk() {
  local instance_name=$1
  local zone=$2

  if gcloud compute disks list --filter=zone:"${zone}" | grep -q "${instance_name}"; then
    gcloud compute disks delete "${instance_name}" -q --zone="${zone}"
  else
    echo "[WARN] There are no disks attached to instance name ${instance_name}"
  fi
}


#
# Instance methods
#

# Checks if an instance exists. Echoes 0 if it exists, 1 otherwise
checkInstanceExistance() {
  local instance_name=${1}

  gcloud compute instances list | grep -q "${instance_name}"
  echo "$?"
}

# Echoes the instance zone
getInstanceZone() {
  local instance_name=${1}

  local instance_zone
  instance_zone=$(gcloud compute instances list | grep "${instance_name}" | awk '{ print $2 }')
  echo "${instance_zone}"
}

# Creates a base instance
createBaseInstance() {
  local instance_name=${1}
  local service_account=${2}
  local project_name=${3}
  local zone=${4}
  local disk_size=${5}

  #local ubuntu_image="ubuntu-minimal-1810-cosmic-v20190628"
  local ubuntu_image="ubuntu-minimal-1804-bionic-v20190911"
  #local ubuntu_image="ubuntu-1804-bionic-v20190911"
  #local ubuntu_image="ubuntu-minimal-1804-lts"

  gcloud compute instances create "${instance_name}" \
    --zone "${zone}" \
    --machine-type n1-standard-1 \
    --image "${ubuntu_image}" \
    --image-project ubuntu-os-cloud \
    --boot-disk-type pd-standard \
    --boot-disk-size "${disk_size}"GB \
    --boot-disk-device-name "${instance_name}" \
    --service-account "${service_account}"
}

createInstance() {
  local instance_name=$1
  local zone=$2
  local node_type=$3
  local service_account=$4

  gcloud compute instances create "${instance_name}" \
    --zone="${zone}" \
    --machine-type "${node_type}" \
    --service-account "${service_account}" \
    --disk "name=${instance_name},device-name=${instance_name},mode=rw,boot=yes,auto-delete=yes" \
    --scopes="storage-full"
}

# Stops a running instance
stopInstance() {
  local instance_name=${1}

  gcloud compute instances stop "${instance_name}"
}

# Removes the given instance
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

# Does a snapshot of an instance
doSnapshot() {
  local base_instance_name=${1}
  local snapshot_name=${2}
  #local disk_zone=${3}
  # TODO: We should compute the disk zone

  # Get disk name
  disk_name=$(gcloud compute instances describe "${base_instance_name}" | grep -A5 disk | grep deviceName | awk '{ print $2 }')

  # Clean previous snapshot if any
  if gcloud compute snapshots list | grep "${snapshot_name}"; then
    echo "[INFO] Cleaning previous snapshot"
    gcloud compute snapshots delete "${snapshot_name}" -q
  fi

  echo "[INFO] Snapshoting..."
  gcloud compute disks snapshot "${disk_name}" --snapshot-names "${snapshot_name}"
}
