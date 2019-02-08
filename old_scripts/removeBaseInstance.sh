#!/bin/bash

source configure.sh
echo ${instanceName}
echo ${currentZone}
removeInstance.sh ${instanceName} ${currentZone}

