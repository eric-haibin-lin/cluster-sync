#!/bin/bash

if [ $# -ne 7 ]; then
    echo 'usage: ';
    echo 'bash dependency.sh dmlc master mxnet-cu90==1.5.0b20190412 bert-baseline 196b65b 90 py27';
    echo 'bash dependency.sh eric-haibin-lin raw mxnet-cu101==1.5.0b20190525 bert-baseline-raw 2177746 101 py36'; 
    echo 'bash dependency.sh eric-haibin-lin raw mxnet-cu101==1.6.0b20190725 bert-baseline-raw 4376ac 101 py36';
    echo "number of arguments received=$#";
    exit -1;
fi

rm -f ~/.status

export REMOTE=$1;
export BRANCH=$2;
export MX_PIP=$3;
export EXP=$4;
export HVD=$5;
export CUDA=$6
export PY_VERSION=$7

echo "==================== arguments ==================== ";
echo "remote=$REMOTE, branch=$BRANCH, mxnet pip version=$MX_PIP, experiment=$EXP, horovod commit=$HVD, python version=$PY_VERSION";

if [ $PY_VERSION = 'py27' ]; then
  export PY='python27';
  export PIP='pip';
fi
if [ $PY_VERSION = 'py36' ]; then
  export PY='python3';
  export PIP='pip3';
fi

wget -q -O mount.sh https://gist.github.com/eric-haibin-lin/b7569d7ada15ca16a1815713880387fc/raw/c76e78bc38759d5be67757355bce9be28312fb67/mount.sh
bash mount.sh

echo "==================== checking cuda $CUDA...  ==================== ";
if [ $CUDA = '101' ]; then
  sudo rm -f /usr/local/cuda; sudo ln -s /usr/local/cuda-10.1 /usr/local/cuda;
fi
if [ $CUDA = '90' ]; then
  sudo rm -f /usr/local/cuda; sudo ln -s /usr/local/cuda-9.0 /usr/local/cuda;
fi

echo "==================== cloning $REMOTE/gluon-nlp:$BRANCH ==================== ";
git clone -b $BRANCH https://github.com/$REMOTE/gluon-nlp /fsx/$EXP || true;

$PIP -q install sentencepiece --user;

echo "==================== installing MXNet $MX_PIP ==================== ";
$PIP -q uninstall mxnet-cu90 -y;
$PIP -q uninstall mxnet-cu100 -y;
$PIP -q uninstall mxnet-cu101 -y;
$PIP -q install $MX_PIP --user -U --no-cache-dir;
$PIP list | grep mx;

echo '=================== installing horovod ==================== ';
git clone https://github.com/uber/horovod --recursive ~/horovod || true;
sleep 10;
cd ~/horovod;
git fetch origin; git reset --hard $HVD; git submodule update --recursive --init;
HOROVOD_GPU_ALLREDUCE=NCCL $PIP -q install . --user --no-cache-dir -U;
$PIP list | grep horovod;

echo "==================== installing $REMOTE/gluon-nlp:$BRANCH ==================== ";
cd /fsx/$EXP;
$PY setup.py -q develop --user;
$PIP list | grep gluon;

echo "==================== installing cluster utility (hudl) ==================== ";
sudo sh -c "curl https://raw.githubusercontent.com/eric-haibin-lin/hudl/master/hudl -o /usr/local/bin/hudl && chmod +x /usr/local/bin/hudl"

echo "$($PIP list | grep mx;)" >> ~/.status
echo "$($PIP list | grep horovod;)" >> ~/.status
echo "$($PIP list | grep gluon;)" >> ~/.status
echo "$($PY -c 'import mxnet; print(mxnet.__version__)')" >> ~/.status
echo "$($PY -c 'import gluonnlp; print(gluonnlp.__version__)')" >> ~/.status
echo "$($PY -c 'import horovod; print(horovod.__version__)')" >> ~/.status