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
  if [ $# -lt 2 ]; then
    echo "[ERROR+ Incorrect number of parameters"
    echo "  Usage: $0 <cus> <num_workers> [worker_ip1] [worker_ip2]..."
    exit 1
  fi

  cus=$1
  num_workers=$2
  shift 2

  worker_ips=( "$@" )
}

create_xml_files() {
  echo "[INFO] Creating XML files"
  COMPSS_HOME=/opt/COMPSs

  # Create information for generation scripts
  info=""
  for (( i=0; i<num_workers; i++ )); do
    worker_info="${worker_ips[$i]}:$cus:$COMPSS_HOME:/tmp/COMPSsWorker$i"
    info="$info ${worker_info}"
  done

  # Generate project.xml
  echo "[INFO] Generating project.xml"
  project_file="${SCRIPT_DIR}/project.xml"
  ${COMPSS_HOME}/Runtime/scripts/system/xmls/generate_project.sh "${project_file}" "${info}"
  echo "[INFO] project.xml generation DONE at ${project_file}"
  # echo "[DEBUG] project.xml content:"
  # cat "${project_file}"

  # Generate resources.xml
  echo "[INFO] Generating resources.xml"
  resources_file="${SCRIPT_DIR}/resources.xml"
  ${COMPSS_HOME}/Runtime/scripts/system/xmls/generate_resources.sh "${resources_file}" "${info}"
  echo "[INFO] resources.xml generation DONE at ${resources_file}"
  # echo "[DEBUG] resources.xml content:"
  # cat "${resources_file}"

  echo "[INFO] XML files creation DONE"
}


#
# MAIN METHOD
#

main() {
  # Retrieve arguments
  declare -a worker_ips
  get_args "$@"

  # Create project and resources XML files
  create_xml_files
}


#
# ENTRY POINT
#

main "$@"
