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

run() {
  jar_file="${SCRIPT_DIR}"/bucket-guidance/guidance_sha_imp_no.jar
  cfg_file="${SCRIPT_DIR}"/bucket-guidance/config_GERA_200_shapeit_impute.file

  debug=off #debug
  graph=true
  tracing=false

  /opt/COMPSs/Runtime/scripts/user/runcompss \
    --log_level=${debug} \
    --graph=${graph} \
    --tracing=${tracing} \
    \
    --project="${HOME}"/project.xml \
    --resources="${HOME}"/resources.xml \
    \
    --classpath="${jar_file}" \
    --scheduler="es.bsc.compss.scheduler.fifoDataScheduler.FIFODataScheduler" \
    --jvm_workers_opts="-Dcompss.worker.removeWD=false" \
    \
    guidance.Guidance -config_file "${cfg_file}"
}


#
# MAIN METHOD
#

main() {
  run
}


#
# ENTRY POINT
#

main "$@"
