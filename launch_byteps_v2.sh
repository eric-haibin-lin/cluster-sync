### CLUSTER VARIABLES

export DMLC_NUM_WORKER=8
export DMLC_NUM_SERVER=8
# XXX: this cannot be hostname
export DMLC_PS_ROOT_URI=172.31.47.42
export DMLC_PS_ROOT_PORT=12345

num_physical_server=8
server_hosts=server_8
worker_hosts=worker_8

server_docker=haibinlin/byteps-server:c5fd6fc
# the container is built with https://github.com/eric-haibin-lin/docker/commit/f7679b4b4bfe4fcd2fc805b271fdab15f322facc
worker_docker=haibinlin/worker_mxnet:c5fd6fc-1.5-cu90-81a7b1c-81a7b1c

HOME=/home/ec2-user


docker pull "$server_docker"
clush --hostfile $server_hosts 'sudo pkill python; sudo pkill sleep; docker kill $(docker ps -q); docker pull "$server_docker"'
clush --hostfile $worker_hosts 'sudo pkill python; sudo pkill sleep; docker kill $(docker ps -q); docker pull "$worker_docker"'

### BYTEPS ENV VARS

export BYTEPS_PARTITION_BYTES=4096000
export BYTEPS_NCCL_NUM_RINGS=1
export SERVER_PUSH_NTHREADS=1
export MXNET_OMP_MAX_THREADS=8
export MXNET_CPU_WORKER_NTHREADS=1
export BYTEPS_USE_HASH_KEY=1
export BYTEPS_FORCE_DISTRIBUTED=1


COMMON_ENV="export DMLC_NUM_WORKER=$DMLC_NUM_WORKER; \
            export DMLC_NUM_SERVER=$DMLC_NUM_SERVER; \
            export DMLC_PS_ROOT_URI=$DMLC_PS_ROOT_URI; \
            export DMLC_PS_ROOT_PORT=$DMLC_PS_ROOT_PORT;"

SERVER_ENV="$COMMON_ENV \
            export SERVER_PUSH_NTHREADS=$SERVER_PUSH_NTHREADS; \
            export MXNET_OMP_MAX_THREADS=$MXNET_OMP_MAX_THREADS; \
            export MXNET_CPU_WORKER_NTHREADS=$MXNET_CPU_WORKER_NTHREADS;"

DOCKER="nvidia-docker run -v $HOME/.ssh:/root/.ssh -v $HOME/mxnet-data/bert-pretraining/datasets:/data -v $HOME/efs/haibin/13-nodes:/efs --network=host --shm-size=32768m"
LAUNCHER="/usr/local/byteps/launcher/launch.py"
SCRIPT_HOME="/root/gluon-nlp/scripts/bert"
SCHED_CMD="$SERVER_ENV export DMLC_ROLE=scheduler; python $LAUNCHER"
SERVER_CMD="$SERVER_ENV export DMLC_ROLE=server; python $LAUNCHER"

SCHED_TMUX="tmux new -d \"$DOCKER -d $server_docker bash -c '$SCHED_CMD'\""

ssh -o "StrictHostKeyChecking no" $DMLC_PS_ROOT_URI "$SCHED_TMUX"

num_server_iter=0
target_server_iter=$DMLC_NUM_SERVER/$num_physical_server
while true;
do
  if [[ $num_server_iter -ge $target_server_iter ]]
  then
    break
  fi
  SERVER_CMD_DOCKER="$DOCKER -d $server_docker bash -c '$SERVER_CMD'"
  clush --hostfile $server_hosts "$SERVER_CMD_DOCKER"
  echo "launched $num_physical_server servers"
  let "num_server_iter+=1"
done;

## TRAINING SCRIPT ARGUMENTS
DEBUG=0;
DOCKER_DEBUG=0;
BS=65520
ACC=9;
#BS=64512;
#ACC=8;
LR=0.006;
WARMUP_RATIO=0.284;
NUMSTEPS=14063;
NUMSTEPS=7102;
COMMIT="ade21cd4";
CKPTDIR="/efs/$worker_docker/$COMMIT/ckpt_stage1_lamb_63k";

BPS_HOME=/usr/local/byteps

if [ "$DEBUG" == "1" ]; then
   export OPTIONS="--synthetic_data\ --eval_use_npz";
   export LOGINTERVAL=1;
else
   export OPTIONS="--raw";
   export LOGINTERVAL=10;
fi

WORKER_ENV="$COMMON_ENV \
            export BPS_HOME=$BPS_HOME \
            export BYTEPS_LOG_LEVEL=DEBUG \
            export BYTEPS_PARTITION_BYTES=$BYTEPS_PARTITION_BYTES; \
            export BYTEPS_NCCL_NUM_RINGS=$BYTEPS_NCCL_NUM_RINGS; \
            export BYTEPS_USE_HASH_KEY=$BYTEPS_USE_HASH_KEY; \
            export BYTEPS_FORCE_DISTRIBUTED=$BYTEPS_FORCE_DISTRIBUTED; \
            export GPUS=0,1,2,3,4,5,6,7; \
            export LOGINTERVAL=$LOGINTERVAL; \
            export BS=$BS; \
            export LR=$LR; \
            export NO_SHARD=1; \
            export USE_BOUND=1; \
            export ADJUST_BOUND=1; \
            export OPTIONS=$OPTIONS; \
            export OPTIMIZER=lamb2; \
            export WARMUP_RATIO=$WARMUP_RATIO; \
            export NUMSTEPS=$NUMSTEPS; \
            export CKPTDIR=$CKPTDIR; \
            export ACC=$ACC; \
            export DMLC_ROLE=worker;"

count=0
while read -u 10 host;
do
  host=${host%% slots*}
  WORKER_CMD="cd $SCRIPT_HOME; git fetch origin; git reset --hard $COMMIT; $WORKER_ENV export DMLC_WORKER_ID=$count; bash bps.sh; sleep infinity"
  WORKER_CMD_DOCKER="$DOCKER -d $worker_docker bash -c '$WORKER_CMD'"
  echo "$WORKER_CMD_DOCKER on $host"
  if [ "$DOCKER_DEBUG" == "1" ]; then
     ssh -tt -o "StrictHostKeyChecking no" $host "$WORKER_CMD_DOCKER"
  else
     ssh -tt -o "StrictHostKeyChecking no" $host "tmux new -d \"$WORKER_CMD_DOCKER\""
  fi
  let "count+=1"
done 10<$worker_hosts;

clush --hostfile $server_hosts 'docker ps --no-trunc'
clush --hostfile $worker_hosts 'docker ps --no-trunc'
