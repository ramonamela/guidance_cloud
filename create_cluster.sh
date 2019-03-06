#!/bin/bash


#
# BASH OPTIONS
#

#set -e # Allow command errors to clean VMs if required
set -u # Exit when undefined variable
#set -x # Enable bash trace


#
# SCRIPT GLOBAL VARIABLES
#

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )


#
# HELPER METHODS
#

create_cluster() {
  local props_file=$1

  echo "[INFO] Creating cluster with ${NUM_NODES} nodes"

  # Launch create_node in parallel
  declare -a node_pids
  for (( i=0; i<NUM_NODES; i++ )); do
    create_node "${props_file}" $i &
    node_pids[$i]=$!
  done

  # Wait for all
  for (( i=0; i<NUM_NODES; i++ )); do
    wait ${node_pids[$i]}
    ev=$?
    echo "[INFO] Create node $i finished with exit value = $ev"
  done

  echo "DONE"
}

create_node() {
  local props_file=$1
  local node_id=$2

  "${SCRIPT_DIR}"/create_cluster/create_node.sh "${props_file}" "${node_id}"
}


#
# MAIN METHOD
#

main() {
  # Source common methods
  # shellcheck source=./utils/create_commons.sh
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}"/utils/create_commons.sh
  # usage
  # show_version
  # get_args
  # check_args
  # create_internal_props_file
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

  # Retrive arguments
  get_args "$@"

  # Check arguments
  check_args

  # Create props file
  internal_props_file=$(mktemp)
  create_internal_props_file "${internal_props_file}"

  # Create cluster
  create_cluster "${internal_props_file}"
}


#
# ENTRY POINT
#

main "$@"
