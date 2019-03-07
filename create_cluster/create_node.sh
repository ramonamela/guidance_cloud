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
  if [ $# -ne 2 ]; then
    echo "[ERROR] Incorrect number of parameters"
    echo "  Usage: $0 <internal_props_file> <node_id>"
    exit 1
  fi

  internal_props_file=$1
  node_id=$2
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

  # shellcheck source=../utils/create_base_instance.sh
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
  echo "[INFO][${node_id}] Creating new node with id = ${node_id}"

  local service_account
  local current_zone
  local current_name

  service_account=$(getServiceAccount "${BASE_INSTANCE_NAME}")
  current_zone=$(getBucketZone "${BUCKET_NAME}") # "us-east1-c"
  current_name="${CLUSTER_INSTANCE_NAME}$(printf %04d "${node_id}")"

  # Clean previous instances (if any)
  echo "[INFO][${node_id}] Cleaning previous instance and disks"
  removeInstance "${current_name}"
  removeDisk "${current_name}" "${current_zone}"

  # Create new disks, instance, and SSH keys
  echo "[INFO][${node_id}] Creating new disks"
  createDisk "${current_name}" "${SNAPSHOT_NAME}" "${current_zone}"

  echo "[INFO][${node_id}] Creating new instance"
  createInstance "${current_name}" "${current_zone}" "${NODE_TYPE}" "${service_account}"

  echo "[INFO][${node_id}] Adding SSH keys"
  addPublicKey "${current_name}" "${current_zone}" "${USERNAME}" "${PUBLIC_SSH_FILE}"

  # Wait until the image is running
  echo "[INFO][${node_id}] Waiting until the image is running..."
  waitUntilRunning "${current_name}" "${current_zone}" "${USERNAME}"
  current_ip=$(getIP "${current_name}" "${current_zone}")
  echo "[INFO][${node_id}] Image running"

  # Mount disks
  echo "[INFO][${node_id}] Mounting disks"
  ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"
  # shellcheck disable=SC2029
  while ! ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "bash -s" -- < "${SCRIPT_DIR}"/mount_disk.sh "${BUCKET_NAME}"; do
    echo "[INFO][${node_id}] Could not mount disks, retrying..."
    sleep 3s
  done
  echo "[INFO][${node_id}] Disks mounted"

  # DONE
  echo "[INFO][${node_id}] Node ${node_id} DONE"
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