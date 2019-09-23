if [ $# -le 3 ]; then
    echo 'usage: ';
    echo 'bash byteps.sh server worker ip        port role    part    ring group pcie push omp worker';
    echo 'bash byteps.sh 1      1      127.0.0.1 1234 server  4096000 1    4     8    1    8   1';
    exit -1;
fi

export DMLC_NUM_SERVER=$1;
export DMLC_NUM_WORKER=$2;
export DMLC_PS_ROOT_URI=$3;
export DMLC_PS_ROOT_PORT=$4;
export DMLC_ROLE=$5;
export BYTEPS_PARTITION_BYTES=$6;
export BYTEPS_NCCL_NUM_RINGS=$7;
export BYTEPS_NCCL_GROUP_SIZE=$8;
export BYTEPS_PCIE=$9;
export BYTEPS_PUSH=${10};
export BYTEPS_OMP=${11};
export BYTEPS_CPU_WORKER=${12};

if [ $DMLC_ROLE = 'server' ]; then
  export MXNET_OMP_MAX_THREADS=$BYTEPS_OMP
  export SERVER_PUSH_NTHREADS=$BYTEPS_PUSH
  export MXNET_CPU_WORKER_NTHREADS=$BYTEPS_CPU_WORKER
  python /usr/local/byteps/launcher/launch.py

elif [ $DMLC_ROLE = 'scheduler' ]; then
  python /usr/local/byteps/launcher/launch.py
fi
