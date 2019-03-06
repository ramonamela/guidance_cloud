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
  local bucket_name=$1

  mkdir -p "$HOME/${bucket_name}"
  gcsfuse -o nonempty \
    --implicit-dirs \
    -o allow_other \
    --dir-mode "777" \
    "${bucket_name}" "$HOME/${bucket_name}"
}


#
# ENTRY POINT
#

main "$@"