#!/bin/bash


#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable
#set -x # Enable bash trace


#
# SCRIPT GLOBAL VARIABLES
#

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )


#
# HELPER METHODS
#

get_args() {
  if [ $# -ne 3 ]; then
    echo "[ERROR] Incorrect number of parameters"
    echo "  Usage: $0 <internal_props_file> <node_id>"
    exit 1
  fi

  internal_props_file=$1
  current_name=$2
  snapshot_name=$3
}

check_and_load_args() {
  if [ ! -f "${internal_props_file}" ]; then
    echo "[ERROR] Properties file not found: ${internal_props_file}"
    exit 1
  fi

  # shellcheck source=../props/default.props
  # shellcheck disable=SC1091
  source "${internal_props_file}"
  # USERNAME
  # PUBLIC_SSH_FILE
  # PROJECT_NAME
  # BACKEND_SCRIPT
  # IDENTIFICATION_JSON
  # BASE_INSTANCE_NAME
  # OVERRIDE_INSTANCE
  # BUCKET_NAME
  # SNAPSHOT_NAME
  # CLUSTER_INSTANCE_NAME
  # NODE_MEM
  # NODE_CPU
  # NODE_TYPE
  # NUM_NODES

  # shellcheck source=../utils/create_base_instances.sh
  # shellcheck disable=SC1091
  source "${BACKEND_SCRIPT}"
  # initSession
  # setProjectName
  # setProjectProperties
  # getBucketLocation
  # getBucketZone
  # getServiceAccount
  # addPublicKey
  # waitUntilRunning
  # getIP
  # createDisk
  # removeDisk
  # checkInstanceExistance
  # getInstanceZone
  # createBaseInstance
  # createInstance
  # stopInstance
  # removeInstance
  # doSnapshot
}

create_node() {
  echo "[INFO][${current_name}] Creating new node with id = ${current_name}"

  local service_account
  local current_zone

  service_account=$(getServiceAccount "${BASE_INSTANCE_NAME_MASTER}")
  current_zone=$(getBucketZone "${BUCKET_NAME}") # "us-east1-c"

  # Clean previous instances (if any)
  echo "[INFO][${current_name}] Cleaning previous instance and disks"
  removeInstance "${current_name}"
  removeDisk "${current_name}" "${current_zone}"

  # Create new disks, instance, and SSH keys
  echo "[INFO][${current_name}] Creating new disks"
  createDisk "${current_name}" "${snapshot_name}" "${current_zone}"

  echo "[INFO][${current_name}] Creating new instance"
  createInstance "${current_name}" "${current_zone}" "${NODE_TYPE}" "${service_account}"

  echo "[INFO][${current_name}] Adding SSH keys"
  addPublicKey "${current_name}" "${current_zone}" "${USERNAME}" "${PUBLIC_SSH_FILE}"

  # Wait until the image is running
  echo "[INFO][${current_name}] Waiting until the image is running..."
  waitUntilRunning "${current_name}" "${current_zone}" "${USERNAME}"
  current_ip=$(getIP "${current_name}" "${current_zone}")
  echo "[INFO][${current_name}] Image running"

  # Add private/public ssh key
  scp -o "StrictHostKeyChecking no" "${PUBLIC_SSH_FILE}" "${USERNAME}"@"${current_ip}":~/.ssh/
  scp -o "StrictHostKeyChecking no" "${PUBLIC_SSH_FILE::-4}" "${USERNAME}"@"${current_ip}":~/.ssh/

  # Mount disks
  echo "[INFO][${current_name}] Mounting disks"
  ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"
  # shellcheck disable=SC2029
  while ! ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "bash -s" -- < "${SCRIPT_DIR}"/mount_disk.sh "${BUCKET_NAME}"; do
    echo "[INFO][${current_name}] Could not mount disks, retrying..."
    sleep 3s
  done
  echo "[INFO][${current_name}] Disks mounted"

  # TODO: The mount script automount_fuse.sh should be injected to the /etc/init.d to have the fuse mounted between node restarts

  # DONE
  echo "[INFO][${current_name}] Node ${current_name} DONE"
}


#
# MAIN METHOD
#

main() {
  # Retrieve arguments
  get_args "$@"

  # Check arguments
  check_and_load_args

  # Create node
  create_node
}


#
# ENTRY POINT
#

main "$@"
