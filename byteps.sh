if [ $# -le 3 ]; then
    echo 'usage: ';
    echo 'bash byteps.sh num_gpus server worker ip        port role       id';
    echo 'bash byteps.sh 8        1      1      127.0.0.1 1234 scheduler';
    echo 'bash byteps.sh 8        1      1      127.0.0.1 1234 worker     0';
    echo 'bash byteps.sh 8        1      1      127.0.0.1 1234 server';
    exit -1;
fi

export GPUS=$1;
export DMLC_NUM_SERVER=$2;
export DMLC_NUM_WORKER=$3;
export DMLC_PS_ROOT_URI=$4;
export DMLC_PS_ROOT_PORT=$5;
export DMLC_ROLE=$6;
export DMLC_WORKER_ID=$7;

if [ $DMLC_ROLE = 'server' ]; then
  export MXNET_OMP_MAX_THREADS=4
  # 4 threads should be enough for a server
  python /usr/local/byteps/launcher/launch.py
elif [ $DMLC_ROLE = 'worker' ]; then
  export NVIDIA_VISIBLE_DEVICES=0,1; #,2,3,4,5,6,7,8;
  export MXNET_SAFE_ACCUMULATION=1;
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
       --accumulate 1 --model bert_24_1024_16 --batch_size_eval 12 --backend byteps

elif [ $DMLC_ROLE = 'scheduler' ]; then
  python /usr/local/byteps/launcher/launch.py
fi
