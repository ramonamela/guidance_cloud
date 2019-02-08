installGuidanceDependenciesCommands(){

    export DEBIAN_FRONTEND=noninteractive && \
    sudo -E apt-get update && sudo apt-get install -y --no-install-recommends apt-utils vim && \
    sudo -E apt-get install -y --no-install-recommends r-base make git && \
    sudo -E apt-get remove -y g++ gcc && \
    sudo -E apt-get install -y --no-install-recommends g++-6 gcc-6 && \
    sudo ln -sf /usr/bin/gcc-6 /usr/bin/gcc && \
    sudo ln -sf /usr/bin/g++-6 /usr/bin/g++ && \
    sudo rm -f ~/TOOLS && \
    mkdir -p ~/TOOLS && \
    cd ~/TOOLS && \
    wget http://www.well.ox.ac.uk/~gav/resources/archive/qctool_v1.4-linux-x86_64.tgz && \
    tar zxvf qctool_v1.4-linux-x86_64.tgz && \
    rm qctool_v1.4-linux-x86_64.tgz && \
    chmod -R 755 ~/TOOLS/qctool_v1.4-linux-x86_64/ && \
    sudo ln -sf ~/TOOLS/qctool_v1.4-linux-x86_64/qctool /usr/bin/qctool1.4 && \
    sudo -E apt-get install -y --no-install-recommends zlib1g-dev libbz2-dev liblzma-dev && \
    wget https://github.com/samtools/bcftools/releases/download/1.8/bcftools-1.8.tar.bz2 -O bcftools.tar.bz2 && \
    tar -xjvf bcftools.tar.bz2 && \
    rm bcftools.tar.bz2 && \
    cd bcftools-1.8 && \
    make && \
    sudo make prefix=/usr/local/bin install && \
    sudo ln -sf /usr/local/bin/bin/bcftools /usr/bin/bcftools && \
    cd .. && \
    sudo -E apt-get install -y --no-install-recommends ncurses-dev && \
    wget https://github.com/samtools/samtools/releases/download/1.5/samtools-1.5.tar.bz2 -O samtools.tar.bz2 && \
    tar -xjvf samtools.tar.bz2 && \
    rm samtools.tar.bz2 && \
    cd samtools-1.5 && \
    make && \
    sudo make prefix=/usr/local/bin install && \
    sudo ln -sf /usr/local/bin/bin/samtools /usr/bin/samtools && \
    sudo -E apt-get install -y --no-install-recommends libblas-dev liblapack-dev libatlas-base-dev && \
    cd .. && \
    sudo rm -rf plink-ng && \
    git clone https://github.com/chrchang/plink-ng.git && \
    cd plink-ng && \
    rm -rf 2.0 && \
    cd 1.9 && \
    ./plink_first_compile && \
    sudo ln -sf ~/TOOLS/plink-ng/1.9/plink /usr/bin/plink && \
    cd ../../ && \
    wget https://data.broadinstitute.org/alkesgroup/Eagle/downloads/old/Eagle_v2.3.tar.gz && \
    tar -zxvf Eagle_v2.3.tar.gz && \
    rm Eagle_v2.3.tar.gz && \
    rm -r Eagle_v2.3/example/ && \
    sudo ln -sf ~/TOOLS/Eagle_v2.3/eagle /usr/bin/eagle && \
    wget https://mathgen.stats.ox.ac.uk/impute/impute_v2.3.2_x86_64_static.tgz && \
    tar -zxvf impute_v2.3.2_x86_64_static.tgz && \
    rm impute_v2.3.2_x86_64_static.tgz && \
    rm -r impute_v2.3.2_x86_64_static/Example/ && \
    sudo ln -sf ~/TOOLS/impute_v2.3.2_x86_64_static/impute2 /usr/bin/impute2 && \
    wget http://www.well.ox.ac.uk/~gav/resources/archive/snptest_v2.5_linux_x86_64_static.tgz && \
    tar -zxvf snptest_v2.5_linux_x86_64_static.tgz && \
    rm snptest_v2.5_linux_x86_64_static.tgz && \
    rm -rf snptest_v2.5_linux_x86_64_static/example/ && \
    chmod -R 755 ~/TOOLS/snptest_v2.5_linux_x86_64_static/ && \
    sudo ln -sf ~/TOOLS/snptest_v2.5_linux_x86_64_static/snptest_v2.5 /usr/bin/snptest_v2.5 && \
    sudo rm -rf Minimac3 && \
    git clone https://github.com/Santy-8128/Minimac3.git && \
    cd Minimac3 && \
    sudo -E apt-get install -y --no-install-recommends libssl-dev zlib1g-dev && \
    make && \
    sudo ln -sf ~/TOOLS/Minimac3/bin/Minimac3 /usr/bin/minimac3 && \
    cd ..

}

installGuidanceDependencies(){

    local username=${1}
    local IP=${2}

    ssh -o "StrictHostKeyChecking no" ${username}@${IP} "$(typeset -f installGuidanceDependenciesCommands); installGuidanceDependenciesCommands"

}

installCOMPSsCommands(){

    export DEBIAN_FRONTEND=noninteractive && \
    sudo -E apt-get update && sudo apt-get install -y --no-install-recommends apt-utils && \
    dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' | xargs sudo apt-get -y remove && \
    sudo -E apt-get -y --no-install-recommends install openjdk-8-jre openjdk-8-jdk && \
    sudo -E apt-get -y --no-install-recommends install python && \
    sudo -E apt-get -y --no-install-recommends install maven subversion && \
    sudo -E apt-get -y --no-install-recommends install openjdk-8-jdk graphviz xdg-utils && \
    sudo -E apt-get -y --no-install-recommends install libtool automake build-essential && \
    sudo -E apt-get -y --no-install-recommends install openssh-server openssh-client && \
    sudo -E apt-get -y --no-install-recommends install libxml2 libxml2-dev gfortran libpapi-dev papi-tools && \
    sudo -E apt-get -y --no-install-recommends install openmpi-bin openmpi-doc libopenmpi-dev uuid-runtime curl bc git && \
    sudo rm -rf ~/2.4 && cd ~ && \
    git clone https://github.com/bsc-wdc/compss.git 2.4 && \
    cd ~/2.4/ && ./submodules_get.sh && ./submodules_patch.sh && cd - && \
    cat ~/.bashrc | grep -v JAVA_HOME > ~/newbashrc && mv ~/newbashrc ~/.bashrc && \
    echo "export JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/\"" >> ~/.bashrc && \
    cat ~/.bashrc && \
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/" && \
    cd ~/2.4/builders && sudo -E ./buildlocal -M -B -A && cd -

}

installCOMPSs(){

    local username=${1}
    local IP=${2}

    ssh -o "StrictHostKeyChecking no" ${username}@${IP} "$(typeset -f installCOMPSsCommands); installCOMPSsCommands"

}