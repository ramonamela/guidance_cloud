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

check_args() {
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
}

create_node() {
  local node_id=$1

  echo "[INFO][${node_id}] Creating new node with id = ${node_id}"

  local service_account
  local current_zone
  local current_name

  service_account=$(gcloud compute instances describe "${BASE_INSTANCE_NAME}" | grep "email" | tr ":" "\\t" | awk '{ print $NF }')
  current_zone="us-east1-c"
  current_name="${CLUSTER_INSTANCE_NAME}$(printf %04d "${node_id}")"

  # Clean previous instances (if any)
  echo "[INFO][${node_id}] Cleaning previous instance and disks"
  "${SCRIPT_DIR}"/remove_instance.sh "${current_name}" "${current_zone}"
  "${SCRIPT_DIR}"/remove_disk.sh "${current_name}" "${current_zone}"

  # Create new disks, instance, and SSH keys
  echo "[INFO][${node_id}] Creating new disks"
  gcloud compute disks create "${current_name}" \
    --zone="${current_zone}" \
    --source-snapshot "${SNAPSHOT_NAME}"

  echo "[INFO][${node_id}] Creating new instance"
  gcloud compute instances create "${current_name}" \
    --zone="${current_zone}" \
    --machine-type "${NODE_TYPE}" \
    --service-account "${service_account}" \
    --disk "name=${current_name},device-name=${current_name},mode=rw,boot=yes,auto-delete=yes" \
    --scopes="storage-full"

  echo "[INFO][${node_id}] Adding SSH keys"
  "${SCRIPT_DIR}"/add_public_key.sh "${current_name}" "${current_zone}" "${USERNAME}" "${PUBLIC_SSH_FILE}"

  # Wait until the image is running
  echo "[INFO][${node_id}] Waiting until the image is running..."
  current_ip=$(gcloud compute instances list --filter=zone:${current_zone} | grep "${current_name}" | awk '{ print $5 }')
  while ! ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${current_ip}" "exit"; do
    echo "[INFO][${node_id}] Could not establish connection with ${USERNAME}@${current_ip}, retrying..."
    sleep 3s
    current_ip=$(gcloud compute instances list --filter=zone:${current_zone} | grep "${current_name}" | awk '{ print $5 }')
  done
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
    check_args

    # Create node
    create_node "${node_id}"
}


#
# ENTRY POINT
#

main "$@"
