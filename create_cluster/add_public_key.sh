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
  local public_ssh_file=$3

  local tmp_public_key="/tmp/publicKeys${instance_name}.txt"

  # Retrieve instance public keys
  gcloud compute instances stop "${instance_name}" --zone="${current_zone}"
  gcloud compute instances describe "${instance_name}" --zone="${current_zone}" | grep ssh-rsa | xargs -i echo {} > "${tmp_public_key}"

  # Append public keys to file
  current_public_key=$(cat "${public_ssh_file}")
  echo "${instance_name}:${current_public_key}" >> "${tmp_public_key}"

  # Upload new public keys
  gcloud compute instances add-metadata "${instance_name}" \
    --metadata-from-file ssh-keys="${tmp_public_key}" \
    --zone="${current_zone}"
  gcloud compute instances start "${instance_name}" --zone="${current_zone}"

  # Clean public key
  rm "${tmp_public_key}"

  # Return instance ip
  current_ip=$(gcloud compute instances list --filter="${instance_name}" | tail -n 1 | awk '{ print $5 }')
  echo "${current_ip}"
}


#
# ENTRY POINT
#

main "$@"
