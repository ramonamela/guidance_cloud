#!/bin/sh

### BEGIN INIT INFO
# Provides:             bucket-fuse
# Required-Start:       $all
# Required-Stop:        
# Default-Start:        2 3 4 5
# Default-Stop:
# Short-Description:    Mounts the bucket fuse
### END INIT INFO

# Author: COMPSs Support <support-compss@bsc.es>


#
# BASH OPTIONS
#

set -e # Exit when command fails
#set -u # Exit when undefined variable
#set -x # Enable bash trace


#
# SCRIPT CONSTANTS
#

NAME=bucket-fuse
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME


#
# HELPER METHOD
#

create_bucket() {
  local bucket_name="bucket-guidance"
  local bucket_loc="/home/guidanceproject2018/${bucket_name}"

  mkdir -p "${bucket_loc}"
  gcsfuse -o nonempty \
    --implicit-dirs \
    -o allow_other \
    --dir-mode "777" \
    "${bucket_name}" "${bucket_loc}"
}


#
# MAIN METHOD
#

main() {
  echo "Start $NAME"

  case "$1" in
    start)
      echo "Creating bucket..."
      create_bucket
      ;;
    *)
      echo "Nothing to do"
      ;;
  esac

  echo "$NAME DONE"
  exit 0
}


#
# ENTRY POINT
#

main "$@"

