#!/bin/bash

if [ $# -ne 2 ]; then
    echo 'usage: ';
    echo 'bash nlp-install.sh mx-0525-raw-large-cased py27';
    echo "number of arguments received=$#";
    exit -1;
fi

export EXP=$1
export PY_VERSION=$2

if [ $PY_VERSION = 'py35' ]; then
  export PY='python3.5';
  export PIP='pip3';
else
  echo "Unsupported version"
  exit
fi

cd /fsx/$EXP;
$PY setup.py develop --user;
