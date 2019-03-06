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

  if gcloud compute instances list | grep "${instance_name}"; then
    echo "[INFO] Cleaning previous instance ${instance_name}"
    instance_zone=$(gcloud compute instances list | grep "${instance_name}" | awk '{ print $2 }')
    gcloud compute instances delete "${instance_name}" -q --zone="${instance_zone}"
  else
    echo "[WARN] There is no instance with name ${instance_name}"
  fi
}


#
# ENTRY POINT
#

main "$@"
