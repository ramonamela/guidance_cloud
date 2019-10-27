#
# BASH OPTIONS
#

set -e # Exit when command fails
set -u # Exit when undefined variable                                                                                                                                                                                                     
#set -x # Enable bash trace


#
# HELPER METHODS
#

installBasicDependenciesCommands() {
  # Enable error manager
  set -e

  # Add apt utils
  sudo -E apt-get update
  sudo apt-get install -y --no-install-recommends apt-utils
  sudo apt-get install -y --no-install-recommends software-properties-common

  # Install Fuse
  sudo add-apt-repository ppa:longsleep/golang-backports
  sudo apt-get update
  sudo apt-get -y --no-install-recommends install git golang-go fuse

  export GO15VENDOREXPERIMENT=1
  export GOPATH="$HOME/go"
  go get -u github.com/googlecloudplatform/gcsfuse
  sudo mkdir -p /opt/userBin
  sudo mv "$HOME"/go/bin/gcsfuse /opt/userBin/
  rm -rf ~/go
  sudo ln -s /opt/userBin/gcsfuse /bin/gcsfuse
}


installGuidanceDependenciesCommands() {
  # Enable error manager
  set -e

  #sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/'
  #sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update
  sudo apt install -y --no-install-recommends apt-transport-https

  #sudo add-apt-repository -y ppa:marutter/c2d4u3.5
  #sudo apt-get update

  # Install base dependencies
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends apt-utils vim
  #DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq --no-install-recommends tzdata
  #sudo bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends r-base-core make git r-cran-rjags"

  export DEBIAN_FRONTEND=noninteractive && \
#    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' && \
#    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 && \
  DEBIAN_FRONTEND=noninteractive sudo apt-get update && sudo apt-get install -y --no-install-recommends gnupg2 software-properties-common && \
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
  sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' && \
  sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends apt-utils && \
  sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile && \
  sudo bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends r-base r-base-dev r-base-core libcurl4-openssl-dev jags libpq-dev libmariadb-client-lgpl-dev"

  #sudo add-apt-repository -y ppa:marutter/c2d4u3.5
  #sudo apt-get update
  #sudo apt-get install r-cran-rjags

  sudo apt-get remove -y g++ gcc
  sudo apt-get install -y --no-install-recommends g++-7 gcc-7 gfortran-7
  sudo ln -sf /usr/bin/gcc-7 /usr/bin/gcc
  sudo ln -sf /usr/bin/g++-7 /usr/bin/g++
  sudo ln -sf /usr/bin/gfortran-7 /usr/bin/gfortran

  # Install R dependencies
  DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends libcurl4-openssl-dev jags libpq-dev libmariadbclient-dev libmariadb-client-lgpl-dev libssl-dev libblas-dev liblapack-dev libatlas-base-dev
  Rscript ./install_R_dependencies.R
  
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
  
  ## Install MINIMAC3
  local minimac_name="Minimac3"
  local minimac_path="${tools_path}"/"${minimac_name}"
  sudo -E apt-get install -y --no-install-recommends libssl-dev zlib1g-dev
  
  cd "${tools_path}"
  git clone https://github.com/Santy-8128/"${minimac_name}".git
  cd "${minimac_name}"
  sed -i 's/ -Werror//' ./Library/libStatGenForMinimac3/general/Makefile
  make
  sudo ln -sf "${minimac_path}"/bin/Minimac3 /usr/bin/minimac3
  cd -

  ## Install MINIMAC4
  local minimac_4_name="Minimac4"
  local minimac_4_path="${tools_path}"/"${minimac_4_name}"
  sudo -E apt-get install -y --no-install-recommends cmake python-pip python-dev build-essential
  pip install wheel
  pip install setuptools
  pip install cget
  
  cd "${tools_path}"
  git clone https://github.com/Santy-8128/"${minimac_4_name}".git
  cd "${minimac_4_name}"
  #sed -i 's/ -Werror//' ./Library/libStatGenForMinimac3/general/Makefile
  bash install.sh
  sudo ln -sf "${minimac_path}"/release-build/minimac4 /usr/bin/minimac4
  cd -

  ## Install shapeit
  # TODO: Deploy correct shapeit version
  local shapeit_name="shapeit.v2.904.2.6.32-696.18.7.el6.x86_64"
  local shapeit_tgz="shapeit.v2.r904.glibcv2.12.linux.tar.gz"
  local shapeit_path="${tools_path}"/"${shapeit_name}"
  cd "${tools_path}"
  wget https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/"${shapeit_tgz}"
  tar -zxvf "${shapeit_tgz}"
  rm "${shapeit_tgz}"
  chmod -R 775 "${shapeit_path}"
  sudo ln -sf "${shapeit_path}/bin/shapeit" /usr/bin/shapeit

  ## Install Guidance
  cd
  sudo -E apt-get update
  sudo -E apt-get install -y --no-install-recommends maven
  git clone --branch 0.1.1 "https://github.com/ramonamela/guidance.git" guidance
  pushd guidance
  mvn clean install
  cp guidance.jar "${HOME}"
  cp -r ./src/main/R "${HOME}"/R_SCRIPTS
  popd
  rm -rf guidance
}

installCOMPSsCommands() {
  # Enable error manager
  set -e
  
  # Clean APT
  sudo -E apt-get update
  
  # Remove any JAVA version
  dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' | xargs sudo apt-get -y remove
  
  # Install basic COMPSs dependencies
  sudo apt-get -y --no-install-recommends install openjdk-8-jre openjdk-8-jdk
  sudo apt-get -y --no-install-recommends install python
  sudo apt-get -y --no-install-recommends install maven subversion
  sudo apt-get -y --no-install-recommends install graphviz xdg-utils
  sudo apt-get -y --no-install-recommends install libtool automake build-essential
  sudo bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends openssh-server openssh-client"
  sudo apt-get -y --no-install-recommends install libxml2 libxml2-dev gfortran-7 libpapi-dev papi-tools
  sudo apt-get -y --no-install-recommends install openmpi-bin openmpi-doc libopenmpi-dev uuid-runtime curl bc git
  
  # Download and Install COMPSs
  local compss_version="guidance"
  local compss_path="$HOME/compss"
  
  ## Setup bash environment
  # TODO: File paths should be parametrized
  cat << EOF > "$HOME"/newbashrc
# Injected by GUIDANCE-COMPSs setup
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
source ${HOME}/env.sh
# End Injected GUIDANCE-COMPSs setup

EOF
  grep -v "JAVA_HOME" "$HOME"/.bashrc >> "$HOME"/newbashrc
  mv "$HOME"/newbashrc "$HOME"/.bashrc
  #cat ~/.bashrc
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
  
  # Download COMPSs
  sudo rm -rf "${compss_path}"
  cd "$HOME"
  git clone --branch "${compss_version}" https://github.com/bsc-wdc/compss.git
  cd "${compss_path}"
  ./submodules_get.sh
  ./submodules_patch.sh
  cd -
  
  # Install COMPSs
  cd "${compss_path}"/builders
  sudo -E ./buildlocal -M -B -P -A -K
  cd -
}
  
  
#
# ENTRY POINTS
#

installBasicDependencies() {
  local username=${1}
  local ip=${2}

  # shellcheck disable=SC2029
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "$(typeset -f); installBasicDependenciesCommands"
}
  
installGuidanceDependencies() {
  local username=${1}
  local ip=${2}
  
  scp -o "StrictHostKeyChecking no" "${SCRIPT_DIR}"/../utils/install_R_dependencies.R "${username}"@"${ip}":.
  # shellcheck disable=SC2029
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "$(typeset -f); mkdir /home/${username}/R/; installGuidanceDependenciesCommands"
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" rm ./install_R_dependencies.R

  #tmpfile=$(mktemp)
  #filename=$(basename -- ${tmpfile})
  #cat << "EOF" > "${tmpfile}"
 
  #git clone --branch 0.1.1 "https://github.com/ramonamela/guidance.git" guidance
  #pushd guidance
  #mvn clean install
  #cp guidance.jar ${HOME}
  #cp -r ./src/main/R ${HOME}/R_SCRIPTS
  #popd
  #rm -rf guidance
    
#EOF
  #echo "USERNAME:${username}"
  #scp -o "StrictHostKeyChecking no" "${tmpfile}" "${username}"@"${ip}":/home/"${username}/${filename}"
  #ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "bash /home/${username}/${filename}"
  #rm ${tmpfile}
}
  
installCOMPSs() {
  local username=${1}
  local ip=${2}
  
  # shellcheck disable=SC2029
  ssh -o "StrictHostKeyChecking no" "${username}"@"${ip}" "$(typeset -f); installCOMPSsCommands"
}
