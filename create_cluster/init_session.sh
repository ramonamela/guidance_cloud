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


#
# HELPER METHODS
#

get_args() {
  if [ $# -ne 1 ]; then
    echo "[ERROR] Incorrect number of parameters"
    echo "  Usage: $0 <internal_props_file>"
    exit 1
  fi

  internal_props_file=$1
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


init_session() {
  # Initialize backend session
  echo "[INFO] Initializing session backend..."
  initSession "${IDENTIFICATION_JSON}"

  # Set project name
  echo "[INFO] Setting project name in backend..."
  setProjectName "${PROJECT_NAME}"

  # Retrieve basic information
  echo "[INFO] Retrieving basic information..."
  local bucket_location
  local bucket_zone
  local service_account
  bucket_location=$(getBucketLocation "${BUCKET_NAME}")
  bucket_zone=$(getBucketZone "${BUCKET_NAME}")
  service_account=$(getServiceAccountFromJSON "${IDENTIFICATION_JSON}")

  # Set project properties
  echo "[INFO] Setting cloud project properties..."
  setProjectProperties "${bucket_location}"
}


#
# MAIN METHOD
#

main() {
  # Retrieve arguments
  get_args "$@"

  # Check arguments
  check_and_load_args

  # Initialize session
  init_session
}


#
# ENTRY POINT
#

main "$@"
