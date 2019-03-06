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
    echo "  Usage: $0 <props_file> <node_id>"
    exit 1
  fi

  props_file=$1
  node_id=$2
}

check_args() {
  if [ ! -f "${props_file}" ]; then
    echo "[ERROR] Properties file not found: ${props_file}"
    exit 1
  fi

  # shellcheck source=../props/default.props
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}"/"${props_file}"
  # USERNAME
  # PUBLIC_SSH_FILE
  # PROJECT_NAME
  # IDENTIFICATION_JSON
  # BASE_INSTANCE_NAME
  # OVERRIDE_INSTANCE
  # BUCKET_NAME
  # SNAPSHOT_NAME
  # NUM_NODES
}

create_node() {
  local node_id=$1

  echo "[INFO] Creating new node with id = ${node_id}"

  local service_account
  local machine_type
  local current_zone
  local current_name

  service_account=$(gcloud compute instances describe "${BASE_INSTANCE_NAME}" | grep service | awk '{ print $3 }')
  machine_type=$(gcloud compute instances describe "${BASE_INSTANCE_NAME}" | grep machine | awk '{ print $2 }' | tr "/" "\\t" | awk '{ print $NF }')

  current_zone="us-east1-c"
  current_name="${BASE_INSTANCE_NAME}$(printf %04d "${node_id}")"

  # Clean previous instances (if any)
  echo "[INFO] Cleaning previous instance and disks"
  "${SCRIPT_DIR}"/remove_instance.sh "${current_name}" "${current_zone}"
  "${SCRIPT_DIR}"/remove_disk.sh "${current_name}" "${current_zone}"

  # Create new disks and instance
  echo "[INFO] Creating new disks and instance"
  gcloud compute disks create "${current_name}" \
    --zone="${current_zone}" \
    --source-snapshot "${SNAPSHOT_NAME}"
  gcloud compute instances create "${current_name}" \
    --zone="${current_zone}" \
    --machine-type "${machine_type}" \
    --service-account "${service_account}" \
    --disk "name=${current_name},device-name=${current_name},mode=rw,boot=yes,auto-delete=yes" \
     --scopes="storage-full"
  "${SCRIPT_DIR}"/add_public_key.sh "${current_name}" "${current_zone}" "${PUBLIC_SSH_KEY}"

  # Wait until the image is running
  echo "[INFO] Waiting until the image is running..."
  current_ip=$(gcloud compute instances list --filter="${current_name}" --filter=zone:${current_zone} | tail -n 1 | awk '{ print $5 }')
  while ! ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "exit"; do
    echo "Could not establish connection with ${USERNAME}@${current_ip}, retrying..."
    sleep 3s
    current_ip=$(gcloud compute instances list --filter="${current_name}" --filter=zone:${current_zone} | tail -n 1 | awk '{ print $5 }')
  done
  echo "[INFO] Image running"

  # Mount disks
  echo "[INFO] Mounting disks"
  # shellcheck disable=SC2029
  while ! ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "bash -s" -- < "${SCRIPT_DIR}"/mount_disk.sh "${BUCKET_NAME}"; do
    echo "Could not mount disks, retrying..."
    sleep 3s
  done
  echo "[INFO] Disks mounted"

  # DONE
  echo "[INFO] Node ${node_id} DONE"
}


#
# MAIN METHOD
#

main() {
    # Retrieve arguments
    get_args "$@"

    # Check arguments
    check_args

    # Create node
    create_node "${node_id}"
}


#
# ENTRY POINT
#

main "$@"
