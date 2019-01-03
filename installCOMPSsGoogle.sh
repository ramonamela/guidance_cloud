#!/bin/bash

source configure.sh
currentIP=$(gcloud compute instances list --filter="${instanceName}" | tail -n1 | awk '{print $5}')
scp installCOMPSsJava.sh ${instanceUsername}@${currentIP}:/home/${instanceUsername}
ssh ${instanceUsername}@${currentIP} "sudo rm -rf ~/2.4"
ssh ${instanceUsername}@${currentIP} "sh /home/${instanceUsername}/installCOMPSsJava.sh"
ssh ${instanceUsername}@${currentIP} "rm /home/${instanceUsername}/installCOMPSsJava.sh"
ssh ${instanceUsername}@${currentIP} "sudo rm -rf ~/2.4"
