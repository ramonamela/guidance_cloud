#!/bin/bash


#
# BASH OPTIONS
#

set +e # Allow command errors to clean VMs if required
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
  echo "[INFO] Creating cluster with ${NUM_NODES} nodes"

  # Launch create_node in parallel
  declare -a node_pids
  for (( i=0; i<NUM_NODES; i++ )); do
    "${SCRIPT_DIR}"/create_cluster/create_node.sh "${internal_props_file}" "${i}" &
    node_pids[$i]=$!
  done

  # Wait for all
  declare -a node_evs
  for (( i=0; i<NUM_NODES; i++ )); do
    node_evs[$i]=0
    wait ${node_pids[$i]} || node_evs[$i]=1
    echo "[INFO] Create node $i finished with exit value = ${node_evs[$i]}"
  done

  # Check all exit values
  for (( i=0; i<NUM_NODES; i++ )); do
    if [ ${node_evs[$i]} -ne 0 ]; then
      echo "[ERROR] Summary: Node $i has failed"
      global_ev=1
      break
    else
      echo "[INFO] Summary: Node $i has been successfully created"
    fi
  done

  if [ "${global_ev}" -ne 0 ]; then
    echo "[ERROR] A node creation has failed, cleaning all instances..."
    remove_cluster
  else
    echo "[INFO] Creating cluster DONE"
  fi
}

remove_cluster() {
  # Launch remove_node in parallel
  declare -a remove_node_pids
  for (( i=0; i<NUM_NODES; i++ )); do
    "${SCRIPT_DIR}"/create_cluster/remove_node.sh "${internal_props_file}" "${i}" &
    remove_node_pids[$i]=$!
  done

  # Wait for all
  local ev
  for (( i=0; i<NUM_NODES; i++ )); do
    ev=0
    wait ${remove_node_pids[$i]} || ev=1
    echo "[INFO] Removing node $i finished with exit value = ${ev}"
  done
}

setup_cluster() {
  echo "[INFO] Setting up cluster with ${NUM_NODES} nodes"

  # Retrieve master IP
  master_ip=$("${SCRIPT_DIR}"/create_cluster/get_node_ip.sh "${internal_props_file}" 0)
  echo "[INFO] MASTER NODE WILL RUN IN ${master_ip}"

  # Retrieve worker IPs
  num_workers=$((NUM_NODES - 1 ))
  declare -a worker_ips
  for (( i=1; i<NUM_NODES; i++ )); do
    ip=$("${SCRIPT_DIR}"/create_cluster/get_node_ip.sh "${internal_props_file}" "${i}")
    worker_ips[$i]=${ip}
  done

  # Configure master
  scp "${SCRIPT_DIR}"/create_cluster/setup_cluster.sh "${USERNAME}"@"${master_ip}":.
  # shellcheck disable=SC2086  # Array split on purpose
  ssh "${USERNAME}"@"${master_ip}" ./setup_cluster.sh "${NODE_CPUS}" "${num_workers}" ${worker_ips[*]}
  global_ev=$?
  ssh "${USERNAME}"@"${master_ip}" rm -f setup_cluster.sh

  echo "[INFO] Setting up cluster DONE"
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
  # NODE_CPUS
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
  global_ev=0
  create_cluster

  # Setup cluster
  if [ "${global_ev}" -eq 0 ]; then
    setup_cluster
  fi

  exit "${global_ev}"
}


#
# ENTRY POINT
#

main "$@"
