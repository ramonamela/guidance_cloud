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
set_env() {
  # System env variables
  export BCFTOOLSBINARY=/usr/bin/bcftools
  export RSCRIPTBINDIR=/usr/bin/R
  export SAMTOOLSBINARY=/usr/bin/samtools
  export PLINKBINARY=/usr/bin/plink
  export EAGLEBINARY=/usr/bin/eagle
  export QCTOOLBINARY=/usr/bin/qctool1.4
  #export SHAPEITBINARY=/gpfs/home/bsc05/bsc05997/TOOLS/shapeit.v2.r727.linux.x64
  #export SHAPEITBINARY=/gpfs/projects/bsc05/ramon/shapeit.v2.904.3.10.0-693.11.6.el7.x86_64/bin/shapeit
  export SHAPEITBINARY=/home/guidanceproject2018/TOOLS/shapeit/bin/shapeit
  export IMPUTE2BINARY=/usr/bin/impute2
  export SNPTESTBINARY=/usr/bin/snptest_v2.5
  export MINIMAC3BINARY=/usr/bin/minimac3
  #export MINIMAC4BINARY=/apps/MINIMAC4/1.0.0/INTEL/bin/minimac4

  export RSCRIPTDIR=/home/guidanceproject2018/bucket-guidance/R_SCRIPTS/

  export LC_ALL="C"

  # Guidance env variables
  # shellcheck source=./set_environment.sh
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}"/set_environment.sh
}

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
  set_env
  run
}


#
# ENTRY POINT
#

main "$@"
