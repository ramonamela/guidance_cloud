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

remove_node() {
  echo "[INFO][${node_id}] Deleting instance for node with id = ${node_id}"

  local current_name
  current_name="${CLUSTER_INSTANCE_NAME}$(printf %04d "${node_id}")"
  removeInstance "${current_name}"

  # DONE
  echo "[INFO][${node_id}] Node ${node_id} removed"
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
  remove_node
}


#
# ENTRY POINT
#

main "$@"
