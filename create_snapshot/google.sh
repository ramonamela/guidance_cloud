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

loadEnv() {
  local pfile=$1
  # shellcheck source=../props/default.props
  # shellcheck disable=SC1091
  source "${pfile}"
  # USERNAME
  # PUBLIC_SSH_FILE
  # PROJECT_NAME
  # BACKEND_SCRIPT
  # IDENTIFICATION_JSON
  # BASE_INSTANCE_NAME
  # OVERRIDE_INSTANCE
  # BUCKET_NAME
  # SNAPSHOT_NAME
  # NODE_MEM
  # NODE_CPU
  # NODE_TYPE
  # NUM_NODES
  
  # shellcheck source=../utils/utils.sh
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../utils/utils.sh"
  # installGuidanceDependencies
  # installCOMPSs
  
  # shellcheck source=../utils/google.sh
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../utils/google.sh"
  # initSession
  # setProjectName
  # setProjectProperties
  # getBucketLocation
  # getBucketZone
  # checkInstanceExistance
  # getInstanceZone
  # removeInstance
  # getServiceAccount
  # addPublicKey
  # waitUntilRunning
  # createBaseInstance
  # stopInstance
}

createNewBaseInstance() {
  # Creates a new base instance
  createBaseInstance "${BASE_INSTANCE_NAME}" "${service_account}" "${PROJECT_NAME}" "${bucket_zone}"
  # Set up public key
  addPublicKey "${BASE_INSTANCE_NAME}" "${bucket_zone}" "${PUBLIC_SSH_FILE}" "${USERNAME}"
  # Wait until instance is running
  # WARN: SETS UP GLOBAL VARIABLE CURRENT_IP !!!!
  waitUntilRunning "${BASE_INSTANCE_NAME}" "${USERNAME}"
}


#
# MAIN METHOD
#

main() {
  # Retrieve props file
  if [ $# -ne 1 ]; then
    echo "[ERROR] Invalid number of parameters"
    echo "   Usage: $0 <props_file>"
    exit 1
  fi
  props_file=${1}
  
  # Load environment and utils
  loadEnv "${props_file}"
  
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
  service_account=$(getServiceAccount "${IDENTIFICATION_JSON}")
  
  # Set project properties
  echo "[INFO] Setting cloud project properties..."
  setProjectProperties "${bucket_location}"
  
  # Create instance
  echo "[INFO] Creating instance..."
  if [ "${OVERRIDE_INSTANCE}" = "true" ]; then
    removeInstance "${BASE_INSTANCE_NAME}"
    createNewBaseInstance
  else
    local ie
    ie=$(checkInstanceExistance "${BASE_INSTANCE_NAME}")
    if [ "0" -eq "${ie}" ]; then
      echo "[WARN] Creating snapshot from existing instance"
      echo "[WARN] Set the configuration 'override' parameter to \"true\" in order to generate the instance again"
    else
      createNewBaseInstance
    fi
  fi
  
  # Mount FUSE
  # This is done in order to mount a FUSE system on the bucket
  # Look into GCSFuse and https://github.com/s3fs-fuse/s3fs-fuse/wiki/Fuse-Over-Amazon
  echo "[INFO] Mounting FUSE..."
  ssh -q -o "StrictHostKeyChecking no" "${USERNAME}"@"${CURRENT_IP}" "cat /etc/fuse.conf | grep -v user_allow_other > tmp.conf;echo user_allow_other >> tmp.conf;sudo mv tmp.conf /etc/fuse.conf"
  
  # Install Guidance dependencies
  echo "[INFO] Install Guidance dependencies..."
  installGuidanceDependencies "${USERNAME}" "${CURRENT_IP}"
  
  # Install COMPSs
  echo "[INFO] Install COMPSs..."
  installCOMPSs "${USERNAME}" "${CURRENT_IP}"

  # Stopping instance
  echo "[INFO] Stopping instance..."
  stopInstance "${BASE_INSTANCE_NAME}"
  
  echo "DONE"
}


#
# SCRIPT ENTRY POINT
#

main "$@"
