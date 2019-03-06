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
  #local current_zone=$2

  if gcloud compute instances list | grep -q -w "${instance_name}"; then
    gcloud compute instances delete "${instance_name}" -q
  else
    echo "[WARN] There is no instance with name ${instance_name}"
  fi
}


#
# ENTRY POINT
#

main "$@"
