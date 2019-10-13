export DMLC_NUM_WORKER=1
export DMLC_NUM_SERVER=1
# this cannot be hostname
export DMLC_PS_ROOT_URI=172.31.47.42
export DMLC_PS_ROOT_PORT=1234

num_physical_server=1

server_hosts=worker_0
worker_hosts=worker_0

server_docker=haibinlin/byteps-server:c5fd6fc
worker_docker=haibinlin/worker_mxnet:c5fd6fc-0412-cu90-efede6

net=bert_24_1024_16
batch_size=8
CKPTDIR="ckpt_stage1_lamb"

export BYTEPS_PARTITION_BYTES=4096000
export BYTEPS_NCCL_NUM_RINGS=16
#export #byte_num_groups=8
#export #byte_pcie=8
export SERVER_PUSH_NTHREADS=1
export MXNET_OMP_MAX_THREADS=8
export MXNET_CPU_WORKER_NTHREADS=1
export BYTEPS_USE_HASH_KEY=1
export BYTEPS_FORCE_DISTRIBUTED=1
#credit_size=0
#async=0
#timeline=0

COMMON_ENV="export DMLC_NUM_WORKER=$DMLC_NUM_WORKER; \
            export DMLC_NUM_SERVER=$DMLC_NUM_SERVER; \
            export DMLC_PS_ROOT_URI=$DMLC_PS_ROOT_URI; \
            export DMLC_PS_ROOT_PORT=$DMLC_PS_ROOT_PORT;"

SERVER_ENV="$COMMON_ENV \
            export SERVER_PUSH_NTHREADS=$SERVER_PUSH_NTHREADS; \
            export MXNET_OMP_MAX_THREADS=$MXNET_OMP_MAX_THREADS; \
            export MXNET_CPU_WORKER_NTHREADS=$MXNET_CPU_WORKER_NTHREADS;"

DOCKER="nvidia-docker run -v ~/.ssh:/root/.ssh -v /home/ubuntu/mxnet-data/bert-pretraining/datasets:/data --network=host --shm-size=32768m"
LAUNCHER="/usr/local/byteps/launcher/launch.py"
SCRIPT_HOME="/root/gluon-nlp/scripts/bert"
SCHED_CMD="$SERVER_ENV export DMLC_ROLE=scheduler; python $LAUNCHER"
SERVER_CMD="$SERVER_ENV export DMLC_ROLE=server; python $LAUNCHER"

ssh -o "StrictHostKeyChecking no" $DMLC_PS_ROOT_URI tmux new -d "$DOCKER -it $server_docker bash -c '$SCHED_CMD'"

num_server_iter=0
target_server_iter=$DMLC_NUM_SERVER/$num_physical_server
while true;
do
  if [[ $num_server_iter -ge $target_server_iter ]]
  then
    break
  fi
  SERVER_CMD_DOCKER="$DOCKER $server_docker bash -c '$SERVER_CMD'"
  hudl -h $server_hosts -t -v "sudo pkill python; $SERVER_CMD_DOCKER"
  echo "launched $num_physical_server servers"
  let "num_server_iter+=1"
done;

LOGINTERVAL=1;

            #export OPTIONS=--raw; \
WORKER_ENV="$COMMON_ENV \
            export BYTEPS_PARTITION_BYTES=$BYTEPS_PARTITION_BYTES; \
            export BYTEPS_NCCL_NUM_RINGS=$BYTEPS_NCCL_NUM_RINGS; \
            export BYTEPS_USE_HASH_KEY=$BYTEPS_USE_HASH_KEY; \
            export BYTEPS_FORCE_DISTRIBUTED=$BYTEPS_FORCE_DISTRIBUTED; \
            export OPTIONS=--synthetic_data --eval_use_npz; \
            export LOGINTERVAL=$LOGINTERVAL; \
            export GPUS=0,1,2,3,4,5,6,7; \
            DMLC_ROLE=worker;"

count=0
while read -u 10 host;
do
  host=${host%% slots*}
  WORKER_CMD="cd $SCRIPT_HOME; $WORKER_ENV export DMLC_WORKER_ID=$count; bash bps.sh"
  WORKER_CMD_DOCKER="$DOCKER -d $worker_docker bash -c '$WORKER_CMD'"
  echo "$WORKER_CMD_DOCKER on $host"
  ssh -o "StrictHostKeyChecking no" $host tmux new -d "sudo pkill python3; $DOCKER -d $worker_docker bash -c '$WORKER_CMD'"
  let "count+=1"
done 10<$worker_hosts;
