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
#MN_USER=bsc19533 # Also requires a MN_USER priv/public key with the same name


#
# HELPER METHODS
#

create_cluster() {

  # Init session
  "${SCRIPT_DIR}"/create_cluster/init_session.sh "${internal_props_file}"

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
  local master_ip
  master_ip=$("${SCRIPT_DIR}"/create_cluster/get_node_ip.sh "${internal_props_file}" -1)
  echo "[INFO] MASTER NODE WILL RUN IN ${master_ip}"

  # Retrieve worker IPs
  num_workers=$NUM_NODES
  declare -a worker_ips
  for (( i=0; i<NUM_NODES; i++ )); do
    ip=$("${SCRIPT_DIR}"/create_cluster/get_node_ip.sh "${internal_props_file}" "${i}")
    worker_ips[$i]=${ip}
  done

  # Configure master
  local mem_per_cpu=$(getMemory ${NODE_MEM})
	local mem=$((${NODE_CPUS} * ${mem_per_cpu}))
  local bucket_dir="/home/${USERNAME}/${BUCKET_NAME}/tmpForCOMPSs"
  local bucket_dir="/tmp"
  scp -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/create_cluster/setup_cluster.sh "${USERNAME}"@"${master_ip}":.
  # shellcheck disable=SC2086  # Array split on purpose
  ssh -o "StrictHostKeyChecking no" "${USERNAME}"@"${master_ip}" ./setup_cluster.sh "${NODE_CPUS}" "${mem}" "${bucket_dir}" "${num_workers}" ${worker_ips[*]}
  ev=$?
  if [ "$ev" -ne 0 ]; then
    echo "[ERROR] Cannot setup cluster"
    exit $ev
  fi
  ssh -o "StrictHostKeyChecking no" "${USERNAME}"@"${master_ip}" rm -f setup_cluster.sh

  echo "[INFO] Setting up cluster DONE"
  global_ev=0
}

deploy_files() {
  # Retrieve master IP
  local master_ip
  master_ip=$("${SCRIPT_DIR}"/create_cluster/get_node_ip.sh "${internal_props_file}" -1)

  # Deploy execution scripts
  echo "[INFO] Deploying execution scripts to ${master_ip}..."
  scp -v -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/launch.sh "${USERNAME}@${master_ip}:/home/${USERNAME}/launch.sh"
  ev=$?
  if [ "$ev" -ne 0 ]; then
    echo "[ERROR] Cannot deploy launch script"
    exit $ev
  fi

  # Overrides default image environment scripts
  scp -v -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/env_execution.sh "${USERNAME}@${master_ip}:/home/${USERNAME}/env_execution.sh"
  ev=$?
  if [ "$ev" -ne 0 ]; then
    echo "[ERROR] Cannot deploy set_environment script"
    exit $ev
  fi

  scp -v -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/env.sh "${USERNAME}@${master_ip}:/home/${USERNAME}/env.sh"
  ev=$?
  if [ "$ev" -ne 0 ]; then
    echo "[ERROR] Cannot deploy set_environment script"
    exit $ev
  fi

  # TODO: Decide which files should be deployed on cluster creation

  # Deploy guidance sources and cfg files
  # echo "[INFO] Deploying Guidance sources and CFG files to ${master_ip}..."
  # scp -v -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/*.jar "${USERNAME}@${master_ip}:/home/${USERNAME}/${BUCKET_NAME}/"
  # ev=$?
  # if [ "$ev" -ne 0 ]; then
  #   echo "[ERROR] Cannot deploy Guidance JAR file"
  #   exit $ev
  # fi

  # scp -v -r -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/R_SCRIPTS "${USERNAME}@${master_ip}:/home/${USERNAME}/${BUCKET_NAME}/"
  # ev=$?
  # if [ "$ev" -ne 0 ]; then
  #   echo "[ERROR] Cannot deploy R_SCRIPTS"
  #   exit $ev
  # fi

  # scp -v -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/execution/config_* "${USERNAME}@${master_ip}:/home/${USERNAME}/${BUCKET_NAME}/"
  # ev=$?
  # if [ "$ev" -ne 0 ]; then
  #   echo "[ERROR] Cannot deploy configuration files"
  #   exit $ev
  # fi

  # echo "[INFO] Deploying SSH keys to ${master_ip}..."
  # scp -o "StrictHostKeyChecking no" ~/.ssh/${MN_USER}* "${USERNAME}@${master_ip}:/home/${USERNAME}/.ssh/"
  # ev=$?
  # if [ "$ev" -ne 0 ]; then
  #   echo "[ERROR] Cannot deploy MN keys"
  #   exit $ev
  # fi

  # echo "[INFO] Deploying input data to ${master_ip}..."
  # # shellcheck disable=SC2029  # We want variables to be expanded in client side
  # ssh -o "StrictHostKeyChecking no" "${USERNAME}@${master_ip}" scp -v -r -i "/home/${USERNAME}/.ssh/${MN_USER}" "${MN_USER}"@mn1.bsc.es:/gpfs/projects/bsc19/GUIDANCE/inputs "/home/${USERNAME}/${BUCKET_NAME}/"
  # ev=$?
  # if [ "$ev" -ne 0 ]; then
  #   echo "[ERROR] Cannot deploy input data"
  #   exit $ev
  # fi

  echo "[INFO] Deploying files DONE"
  global_ev=0
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
  # getMemory
  # stopInstance
  # removeInstance
  # doSnapshot

  # Create cluster
  global_ev=0
  create_cluster

  # Setup cluster
  if [ "${global_ev}" -eq 0 ]; then
    setup_cluster
    deploy_files
  fi

  exit "${global_ev}"
}


#
# ENTRY POINT
#

main "$@"
