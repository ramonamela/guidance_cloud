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
  if [ $# -lt 4 ]; then
    echo "[ERROR+ Incorrect number of parameters"
    echo "  Usage: $0 <cus> <mem> <bucket_dir> <num_workers> [worker_ip1] [worker_ip2]..."
    exit 1
  fi

  cus=$1
  mem=$2
  bucket_dir=$3
  num_workers=$4
  shift 4

  worker_ips=( "$@" )
}

create_xml_files() {
  echo "[INFO] Creating XML files"
  COMPSS_HOME=/opt/COMPSs

  # Create information for generation scripts
  info=""
  for (( i=0; i<num_workers; i++ )); do
    worker_info="${worker_ips[$i]}:$cus:$COMPSS_HOME:${bucket_dir}/COMPSsWorker$i"
    info="$info ${worker_info}"
  done

  # Generate project.xml
  echo "[INFO] Generating project.xml"
  project_file="${SCRIPT_DIR}/project.xml"
  bucket_dir_for_sed=$(echo "${bucket_dir}" | sed 's/\//\\\//g')
  ${COMPSS_HOME}/Runtime/scripts/system/xmls/generate_project.sh "${project_file}" "${info}"
  #sed -i 's/<MasterNode><\/MasterNode>/<MasterNode><SharedDisks><AttachedDisk Name=\"Bucket\"><MountPoint>'${bucket_dir_for_sed}'<\/MountPoint><\/AttachedDisk><\/SharedDisks><\/MasterNode>/g' "${project_file}"

  echo "[INFO] project.xml generation DONE at ${project_file}"
  # echo "[DEBUG] project.xml content:"
  # cat "${project_file}"

  # Generate resources.xml
  echo "[INFO] Generating resources.xml"
  resources_file="${SCRIPT_DIR}/resources.xml"
  ${COMPSS_HOME}/Runtime/scripts/system/xmls/generate_resources.sh "${resources_file}" "${info}"
  #sed -i 's/<ResourcesList>/<ResourcesList><SharedDisk Name=\"Bucket\"><Storage><Size>1000000.0<\/Size><Type>Persistent<\/Type><\/Storage><\/SharedDisk>/g' "${resources_file}"
  sed -i 's/<\/Processor>/<\/Processor><Memory><Size>'${mem}'<\/Size><\/Memory>/g' "${resources_file}"
  #sed -i 's/<\/Adaptors>/<\/Adaptors><SharedDisks><AttachedDisk Name=\"Bucket\"><MountPoint>'${bucket_dir_for_sed}'<\/MountPoint><\/AttachedDisk><\/SharedDisks>/g' "${resources_file}"
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
