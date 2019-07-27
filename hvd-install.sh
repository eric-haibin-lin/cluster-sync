#!/bin/bash

if [ $# -ne 2 ]; then
    echo 'usage: ';
    echo 'bash hvd-install.sh 2177746 py27';
    echo "number of arguments received = $#";
    exit -1;
fi

export HVD=$1
export PY_VERSION=$2

if [ $PY_VERSION = 'py27' ]; then
  export PY='python27';
  export PIP='pip-2.7';
fi
if [ $PY_VERSION = 'py36' ]; then
  export PY='python36';
  export PIP='pip-3.6';
fi

git clone https://github.com/uber/horovod --recursive ~/horovod || true;
sleep 10;
cd ~/horovod;
git fetch origin; git reset --hard $HVD;
HOROVOD_GPU_ALLREDUCE=NCCL $PIP -q install . --user --no-cache-dir -U;
$PIP list | grep horovod;
