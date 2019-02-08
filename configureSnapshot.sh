## General project information
username="guidanceproject2018"
publicSSHfile="${HOME}/.ssh/id_rsa.pub"
projectName="guidance"
identificationJson="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/guidance-06986d1d6789.json"

## Base instance information
baseInstanceName="guidancebase"
overrideInstance="true"
#baseInstanceZone="us-east1-c"

## Bucket information
bucketName="bucket-${projectName}"
#zone=${currentZone}

## Snapshot name
snapName="snap${projectName}"
