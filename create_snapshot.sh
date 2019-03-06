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
  # create_props_file
  # BACKEND_SCRIPT
  # USERNAME
  # PUBLIC_SSH_FILE
  # PROJECT_NAME
  # IDENTIFICATION_JSON
  # BASE_INSTANCE_NAME
  # OVERRIDE_INSTANCE
  # BUCKET_NAME
  # SNAPSHOT_NAME
  # NUM_NODES

  # Retrive arguments
  get_args "$@"

  # Check arguments
  check_args

  # Create props file
  props_file=$(mktemp)
  create_props_file "${props_file}"

  # Launch backend script
  "${BACKEND_SCRIPT}" "${props_file}"
}


#
# ENTRY POINT
#

main "$@"
