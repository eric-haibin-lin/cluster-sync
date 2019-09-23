if [ $# -le 3 ]; then
    echo 'usage: ';
    echo 'bash byteps.sh server worker ip        port role   id model           bs part    ring group pcie load credit';
    echo 'bash byteps.sh 1      1      127.0.0.1 1234 worker 0  bert_24_1024_16 12 4096000 1    4     8    2    0';
    exit -1;
fi

export DMLC_NUM_SERVER=$1;
export DMLC_NUM_WORKER=$2;
export DMLC_PS_ROOT_URI=$3;
export DMLC_PS_ROOT_PORT=$4;
export DMLC_ROLE=$5;
export DMLC_WORKER_ID=$6;
export MODEL=$7;
export BS=$8;
export BYTEPS_PARTITION_BYTES=${9};
export BYTEPS_NCCL_NUM_RINGS=${10};
export BYTEPS_NCCL_GROUP_SIZE=${11};
export BYTEPS_PCIE=${12};
export BYTEPS_LOAD_BALANCE=${13};
export BYTEPS_SCHEDULING_CREDIT=${14};

if [ $DMLC_ROLE = 'worker' ]; then
  export NVIDIA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7;
  export BYTEPS_FORCE_DISTRIBUTED=1;
  export BYTEPS_LOG_LEVEL=DEBUG;
  export MXNET_SAFE_ACCUMULATION=1;
  export BYTEPS_PCIE_SWITCH_SIZE=$BYTEPS_PCIE;

  if [ $DMLC_WORKER_ID = 999 ]; then
    export EVAL_TYPE=benchmark
    python /usr/local/byteps/launcher/launch.py \
         /usr/local/byteps/example/mxnet/start_mxnet_byteps.sh \
         --benchmark 1 --batch-size=32
  fi
  python3 /usr/local/byteps/launcher/launch.py \
       python3 run_pretraining_hvd.py --data='~/mxnet-data/bert-pretraining/datasets/*/*/*.train,' \
       --data_eval='~/mxnet-data/bert-pretraining/datasets/*/*/*.dev,' --num_steps 1000000        \
       --lr 1e-4 --batch_size 4096 --accumulate 1 --raw --short_seq_prob 0 --log_interval 10 \
       --accumulate 1 --model $MODEL --batch_size_eval $BS --backend byteps 2>&1 | tee -a result.log
fi
