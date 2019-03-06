#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable                                                                                                                                                                                                     
#set -x # Enable bash trace


#
# HELPER METHODS
#

installGuidanceDependenciesCommands() {
  # Enable error manager
  set -e
  
  # Install base dependencies
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends apt-utils vim
  sudo bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends r-base make git"
  sudo apt-get remove -y g++ gcc
  sudo apt-get install -y --no-install-recommends g++-6 gcc-6
  sudo ln -sf /usr/bin/gcc-6 /usr/bin/gcc
  sudo ln -sf /usr/bin/g++-6 /usr/bin/g++
  
  # Install Guidance tools
  
  ## Create TOOLS dir from scratch
  local tools_path="$HOME"/TOOLS
  sudo rm -f "${tools_path}"
  mkdir -p "${tools_path}"
  
  ## Install QC Tool
  local qctool_name="qctool_v1.4-linux-x86_64"
  local qctool_tgz="${qctool_name}".tgz
  local qctool_path="${tools_path}"/"${qctool_name}"
  
  cd "${tools_path}"
  wget http://www.well.ox.ac.uk/~gav/resources/archive/"${qctool_tgz}"
  tar zxvf "${qctool_tgz}"
  rm "${qctool_tgz}"
  chmod -R 755 "${qctool_path}"
  sudo ln -sf "${qctool_path}"/qctool /usr/bin/qctool1.4
  
  ## Install BCF TOOLS
  local bcftools_name="bcftools-1.8"
  local bcftools_tgz="${bcftools_name}".tar.bz2
  sudo apt-get install -y --no-install-recommends zlib1g-dev libbz2-dev liblzma-dev
  
  cd "${tools_path}"
  wget https://github.com/samtools/bcftools/releases/download/1.8/${bcftools_tgz}
  tar -xjvf ${bcftools_tgz}
  rm "${bcftools_tgz}"
  cd ${bcftools_name}
  make
  sudo make prefix=/usr/local/bin install
  sudo ln -sf /usr/local/bin/bin/bcftools /usr/bin/bcftools
  cd -
  
  ## Install SAM TOOLS
  local samtools_name="samtools-1.5"
  local samtools_tgz="${samtools_name}".tar.bz2
  sudo apt-get install -y --no-install-recommends ncurses-dev
  sudo apt-get install -y --no-install-recommends libblas-dev liblapack-dev libatlas-base-dev
  
  cd "${tools_path}"
  wget https://github.com/samtools/samtools/releases/download/1.5/${samtools_tgz}
  tar -xjvf ${samtools_tgz}
  rm "${samtools_tgz}"
  cd ${samtools_name}
  make
  sudo make prefix=/usr/local/bin install
  sudo ln -sf /usr/local/bin/bin/samtools /usr/bin/samtools
  cd -
  
  ## Install PLINK
  local plink_name="plink-ng"
  local plink_path="${tools_path}"/"${plink_name}"
  
  cd "${tools_path}"
  git clone https://github.com/chrchang/"${plink_name}".git
  cd "${plink_name}"
  rm -rf 2.0
  cd 1.9
  ./plink_first_compile
  sudo ln -sf "${plink_path}"/1.9/plink /usr/bin/plink
  cd "${tools_path}"
  
  ## Install EAGLE
  local eagle_name="Eagle_v2.3"
  local eagle_tgz="${eagle_name}".tar.gz
  local eagle_path="${tools_path}"/"${eagle_name}"
  
  cd "${tools_path}"
  wget https://data.broadinstitute.org/alkesgroup/Eagle/downloads/old/"${eagle_tgz}"
  tar -zxvf "${eagle_tgz}"
  rm "${eagle_tgz}"
  rm -r "${eagle_path}"/example/
  sudo ln -sf "${eagle_path}"/eagle /usr/bin/eagle
  
  ## Install Impute
  local impute_name="impute_v2.3.2_x86_64_static"
  local impute_tgz="${impute_name}".tgz
  local impute_path="${tools_path}"/"${impute_name}"
  
  cd "${tools_path}"
  wget https://mathgen.stats.ox.ac.uk/impute/"${impute_tgz}"
  tar -zxvf "${impute_tgz}"
  rm "${impute_tgz}"
  rm -r "${impute_path}"/Example/
  sudo ln -sf "${impute_path}"/impute2 /usr/bin/impute2
  
  ## Install SNP Test
  local snp_name="snptest_v2.5_linux_x86_64_static"
  local snp_tgz="${snp_name}".tgz
  local snp_path="${tools_path}"/"${snp_name}"
  
  cd "${tools_path}"
  wget http://www.well.ox.ac.uk/~gav/resources/archive/"${snp_tgz}"
  tar -zxvf "${snp_tgz}"
  rm "${snp_tgz}"
  rm -r "${snp_path}"/example
  chmod -R 755 "${snp_path}"
  sudo ln -sf "${snp_path}"/snptest_v2.5 /usr/bin/snptest_v2.5
  
  ## Install MINIMAC
  local minimac_name="Minimac3"
  local minimac_path="${tools_path}"/"${minimac_name}"
  sudo -E apt-get install -y --no-install-recommends libssl-dev zlib1g-dev
  
  cd "${tools_path}"
  git clone https://github.com/Santy-8128/"${minimac_name}".git
  cd "${minimac_name}"
  make
  sudo ln -sf "${minimac_path}"/bin/Minimac3 /usr/bin/minimac3
  cd -
}

installCOMPSsCommands() {
  # Enable error manager
  set -e
  
  # Clean APT
  sudo -E apt-get update
  sudo apt-get install -y --no-install-recommends apt-utils
  
  # Remove any JAVA version
  dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' | xargs sudo apt-get -y remove
  
  # Install basic COMPSs dependencies
  sudo apt-get -y --no-install-recommends install openjdk-8-jre openjdk-8-jdk
  sudo apt-get -y --no-install-recommends install python
  sudo apt-get -y --no-install-recommends install maven subversion
  sudo apt-get -y --no-install-recommends install graphviz xdg-utils
  sudo apt-get -y --no-install-recommends install libtool automake build-essential
  sudo bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends openssh-server openssh-client"
  sudo apt-get -y --no-install-recommends install libxml2 libxml2-dev gfortran libpapi-dev papi-tools
  sudo apt-get -y --no-install-recommends install openmpi-bin openmpi-doc libopenmpi-dev uuid-runtime curl bc git
  
  # Download and Install COMPSs
  local compss_version="2.4"
  local compss_path="$HOME"/"${compss_version}"
  
  ## Setup bash environment
  grep -v "JAVA_HOME" "$HOME"/.bashrc > "$HOME"/newbashrc
  echo "export JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/\"" >> "$HOME"/newbashrc
  mv "$HOME"/newbashrc "$HOME"/.bashrc
  #cat ~/.bashrc
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
  
  # Download COMPSs
  sudo rm -rf "${compss_path}"
  cd "$HOME"
  git clone https://github.com/bsc-wdc/compss.git "${compss_version}"
  cd "${compss_path}"
  ./submodules_get.sh
  ./submodules_patch.sh
  cd -
  
  # Install COMPSs
  cd "${compss_path}"/builders
  sudo -E ./buildlocal -M -B -A
  cd -
  }
  
  
  #
  # ENTRY POINTS
  #
  
  installGuidanceDependencies() {
  local username=${1}
  local ip=${2}
  
  # shellcheck disable=SC2029
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "$(typeset -f); installGuidanceDependenciesCommands"
  }
  
  installCOMPSs() {
  local username=${1}
  local ip=${2}
  
  # shellcheck disable=SC2029
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "$(typeset -f); installCOMPSsCommands"
}
