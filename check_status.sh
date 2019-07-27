#!/bin/bash
if [ $# -ne 1 ]; then
    echo 'usage: ';
    echo 'bash check_status.sh py35';
    echo "number of arguments received=$#";
    exit -1;
fi

export PY_VERSION=$1

if [ $PY_VERSION = 'py35' ]; then
  export PY='python3.5';
  export PIP='pip3';
else
  echo "Unsupported version"
  exit
fi

rm -f ~/.status;
echo "$($PIP list | grep mx;)" >> ~/.status;
echo "$($PIP list | grep horovod;)" >> ~/.status;
echo "$($PIP list | grep gluon;)" >> ~/.status;
echo "$($PIP list | grep mx;)"
echo "$($PIP list | grep horovod;)"
echo "$($PIP list | grep gluon;)"
