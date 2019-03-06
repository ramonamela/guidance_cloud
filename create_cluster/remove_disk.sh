#!/bin/bash


#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable
#set -x # Enable bash trace


#
# MAIN METHOD
#

main() {
  local instance_name=$1
  local current_zone=$2

  if gcloud compute disks list --filter=zone:"${current_zone}" | grep -q "${instance_name}"; then
    gcloud compute disks delete "${instance_name}" -q --zone="${current_zone}"
  else
    echo "[WARN] There are no disks attached to instance name ${instance_name}"
  fi
}


#
# ENTRY POINT
#

main "$@"
