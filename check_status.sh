#!/bin/bash
export PY_VERSION=$1

if [ $PY_VERSION = 'py27' ]; then
  export PY='python27';
  export PIP='pip';
fi
if [ $PY_VERSION = 'py36' ]; then
  export PY='python36';
  export PIP='pip3';
fi

rm -f ~/.status;
echo "$($PIP list | grep mx;)" >> ~/.status;
echo "$($PIP list | grep horovod;)" >> ~/.status;
echo "$($PIP list | grep gluon;)" >> ~/.status;
echo "$($PY -c 'import mxnet; print(mxnet.__version__)')" >> ~/.status;
echo "$($PY -c 'import gluonnlp; print(gluonnlp.__version__)')" >> ~/.status;
echo "$($PY -c 'import horovod; print(horovod.__version__)')" >> ~/.status;