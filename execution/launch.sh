#!/bin/bash


#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable
#set -x # Enable bash trace

export export R_LIBS="~/R/"

#
# SCRIPT GLOBAL VARIABLES
#

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )


#
# HELPER METHODS
#

run() {
  jar_file="${HOME}"/guidance.jar
  cfg_file="/home/computational.genomics.bsc/guidance_bucket/config_GERA_1000_shapeit_impute_1_23_cloud.file"
  output_dir=$(cat ${cfg_file} | grep outputdir | awk '{ print $3 }')
	mkdir -p ${output_dir}
  
  source /home/computational.genomics.bsc/env_execution.sh

  debug=off #debug
  graph=true
  tracing=true

  /opt/COMPSs/Runtime/scripts/user/runcompss \
    --log_level=${debug} \
    --graph=${graph} \
    --tracing=${tracing} \
    \
    --project="${HOME}"/project.xml \
    --resources="${HOME}"/resources.xml \
    \
    --classpath="${jar_file}" \
    --scheduler="es.bsc.compss.scheduler.fifodatanew.FIFODataScheduler" \
    --jvm_workers_opts="-Dcompss.worker.removeWD=true" \
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
