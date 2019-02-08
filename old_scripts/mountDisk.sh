#!/bin/bash

bucketName=${1}

mkdir -p $HOME/${bucketName}
gcsfuse -o nonempty --implicit-dirs -o allow_other --dir-mode "777" ${bucketName} $HOME/${bucketName}
## sudo -H -u myusername ....
#gcsfuse --implicit-dirs --dir-mode "777" -o allow_other -o nonempty bucket-guidance $HOME/bucket-guidance

#mkdir -p $HOME/bucket-guidance
#gcsfuse -o nonempty --implicit-dirs --dir-mode "774" bucket-guidance $HOME/bucket-guidance
