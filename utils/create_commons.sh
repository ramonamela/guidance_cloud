#!/bin/bash

#
# BASH OPTIONS
#

set -e # Exit when command fails
#set -u # Exit when undefined variable
#set -x # Enable bash trace


#
# SCRIPT GLOBAL VARIABLES
#

COMMONS_SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
DEFAULT_CLOUD_BACKEND="google"


#
# SOURCEABLE METHODS
#

usage() {
  cat <<EOT
Usage: $0 [options]

  * Options:
    -v                                 Display version
    -h                                 Display help message

    --help                             Display help message
    --version                          Display version

    --backend=<backend>                Set cloud backend
                                       Default: ${DEFAULT_CLOUD_BACKEND}
    --props=<filename>                 Loads variables from properties file

    --username=<string>                Sets username variable
    --public_ssh_file=<file>           Sets public ssh file
    --project_name=<string>            Sets project name
    --identification_json=<file>       Sets identification JSON file
    --base_instance_name=<string>      Sets base instance name
    --override_instance=<boolean>      When activated, overrides the base instance
    --bucket_name=<string>             Sets the bucket name
    --snapshot_name=<string>           Sets the snapshot name
    --cluster_instance_name=<string>   Sets the cluster images name
    --node_mem=<string>                Memory size per node <standard, highmem, highcpu>
    --node_cpus=<int>                  Number of CPUs per node
    --num_nodes=<int>                  Number of nodes for the cluster

EOT
}

show_version() {
  echo "Cloud Utils v0.1"
  echo " "
}

get_args() {
  # Parse COMPSs Options
  while getopts hv-: flag; do
  # Treat the argument
    case "$flag" in
      h)
        # Display help
        usage
        exit 0
        ;;
      v)
        # Display version
        show_version
        exit 0
        ;;
      -)
        # Check more complex arguments
        case "$OPTARG" in
          help)
            # Display help
            usage
            exit 0
            ;;
          version)
            show_version
            exit 0
            ;;
          backend=*)
            backend=${OPTARG//backend=/}
            ;;
          props=*)
            props_file=${OPTARG//props=/}
            ;;
          username=*)
            USERNAME=${OPTARG//username=/}
            ;;
          public_ssh_file=*)
            PUBLIC_SSH_FILE=${OPTARG//public_ssh_file=/}
            ;;
          project_name=*)
            PROJECT_NAME=${OPTARG//project_name=/}
            ;;
          identification_json=*)
            IDENTIFICATION_JSON=${OPTARG//identification_json=/}
            ;;
          base_instance_name=*)
            BASE_INSTANCE_NAME=${OPTARG//base_instance_name=/}
            ;;
          override_instance=*)
            OVERRIDE_INSTANCE=${OPTARG//override_instance=/}
            ;;
          bucket_name=*)
            BUCKET_NAME=${OPTARG//bucket_name=/}
            ;;
          snapshot_name=*)
            SNAPSHOT_NAME=${OPTARG//snapshot_name=/}
            ;;
          cluster_instance_name=*)
            CLUSTER_INSTANCE_NAME=${OPTARG//cluster_instance_name=/}
            ;;
          node_mem=*)
            NODE_MEM=${OPTARG//node_mem=/}
            ;;
          node_cpus=*)
            NODE_CPUS=${OPTARG//node_cpus=/}
            ;;
          num_nodes=*)
            NUM_NODES=${OPTARG//num_nodes=/}
            ;;
          *)
            # Flag didn't match any patern. Raise exception
            echo "[ERROR] Invalid argument: $OPTARG"
            exit 1
            ;;
        esac
        ;;
      *)
        # Flag didn't match any patern. Raise exception
        echo "[ERROR] Invalid argument: $flag"
        exit 1
        ;;
    esac
  done
}


check_args() {
  # Check cloud backend
  backend=${backend:-$DEFAULT_CLOUD_BACKEND}
  BACKEND_SCRIPT=${COMMONS_SCRIPT_DIR}/../backends/${backend}.sh
  if [ ! -f "${BACKEND_SCRIPT}" ]; then
    echo "[ERROR] Invalid backend ${backend}"
    echo "[ERROR] Dependant script ${BACKEND_SCRIPT} not found"
    exit 1
  fi
  
  # Load properties file if specified
  if [ -n "${props_file}" ]; then
    echo "[INFO] Loading parameters from properties file ${props_file}"
    echo "[WARN] Command arguments will be overriden by file definitions"
    # shellcheck source=./props/default.props
    # shellcheck disable=SC1091
    source "${COMMONS_SCRIPT_DIR}/../props/${props_file}"
  fi
  
  # Check required variables (may have been loaded from props file)
  if [ -z "${USERNAME}" ]; then
    echo "[ERROR] USERNAME not defined"
    exit 1
  fi
  
  if [ -z "${PUBLIC_SSH_FILE}" ]; then
    echo "[ERROR] PUBLIC_SSH_FILE not defined"
    exit 1
  fi
  
  if [ -z "${PROJECT_NAME}" ]; then
    echo "[ERROR] PROJECT_NAME not defined"
    exit 1
  fi
  
  if [ -z "${IDENTIFICATION_JSON}" ]; then
    echo "[ERROR] IDENTIFICATION_JSON not defined"
    exit 1
  fi
  
  if [ -z "${BASE_INSTANCE_NAME}" ]; then
    echo "[ERROR] BASE_INSTANCE_NAME not defined"
    exit 1
  fi
  
  if [ -z "${OVERRIDE_INSTANCE}" ]; then
    echo "[ERROR] OVERRIDE_INSTANCE not defined"
    exit 1
  fi
  
  if [ -z "${BUCKET_NAME}" ]; then
    echo "[ERROR] BUCKET_NAME not defined"
    exit 1
  fi
  
  if [ -z "${SNAPSHOT_NAME}" ]; then
    echo "[ERROR] SNAPSHOT_NAME not defined"
    exit 1
  fi

  if [ -z "${CLUSTER_INSTANCE_NAME}" ]; then
    echo "[ERROR] CLUSTER_INSTANCE_NAME not defined"
    exit 1
  fi
  
  if [ -z "${NODE_MEM}" ]; then
    echo "[ERROR] NODE_MEM not defined"
    exit 1
  fi
  
  if [ -z "${NODE_CPUS}" ]; then
    echo "[ERROR] NODE_CPUS not defined"
    exit 1
  fi
  
  if [ -z "${NUM_NODES}" ]; then
    echo "[ERROR] NUM_NODES not defined"
    exit 1
  fi

  # Check and define NODE_TYPE
  declare -a correct_options
  if [ "${NODE_MEM}" == "standard" ]; then
    correct_options=(1 2 4 8 16 32 64 96)
  else
    if [ "${NODE_MEM}" == "highcpu" ] || [ "${NODE_MEM}" == "highmem" ]; then
      correct_options=(2 4 8 16 32 64 96)
    else
      echo "[ERROR] Unrecognised NODE_MEMORY = ${NODE_MEM}"
      exit 1
    fi
  fi
  # Check that the NODE_CPUS is correct
  local is_valid=1
  for correct_opt in "${correct_options[@]}"; do
	if [ "${NODE_CPUS}" -eq "${correct_opt}" ]; then
	  is_valid=0
	  break
	fi
  done
  if [ "${is_valid}" -ne 0 ]; then
    echo "[ERROR] Unsupported number of cpus ${NODE_CPUS}"
    exit 1
  fi
  # Define the NODE_TYPE
  NODE_TYPE="n1-${NODE_MEM}-${NODE_CPUS}"
}

create_internal_props_file() {
  local pfile=$1

  cat > "${pfile}" <<EOT
# General project information
USERNAME=${USERNAME}
PUBLIC_SSH_FILE=${PUBLIC_SSH_FILE}
PROJECT_NAME=${PROJECT_NAME}
IDENTIFICATION_JSON=${IDENTIFICATION_JSON}
BACKEND_SCRIPT=${BACKEND_SCRIPT}

# Base instance information
BASE_INSTANCE_NAME=${BASE_INSTANCE_NAME}
OVERRIDE_INSTANCE=${OVERRIDE_INSTANCE}

# Bucket information
BUCKET_NAME=${BUCKET_NAME}

# Snapshot name
SNAPSHOT_NAME=${SNAPSHOT_NAME}

# Cluster information
CLUSTER_INSTANCE_NAME=${CLUSTER_INSTANCE_NAME}
NODE_MEM=${NODE_MEM}
NODE_CPUS=${NODE_CPUS}
NODE_TYPE=${NODE_TYPE}
NUM_NODES=${NUM_NODES}
EOT
}