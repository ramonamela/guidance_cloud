#!/bin/bash

sudo apt-get install golang fuse && \
export GO15VENDOREXPERIMENT=1 && \
export GOPATH="$HOME/go" && \
go get -u github.com/googlecloudplatform/gcsfuse && \
sudo mkdir -p /opt/userBin && \
sudo mv $HOME/go/bin/gcsfuse /opt/userBin/ && \
rm -rf ~/go && \
sudo ln -s /opt/userBin/gcsfuse /bin/gcfuse
