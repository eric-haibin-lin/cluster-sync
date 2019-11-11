### CLUSTER VARIABLES
# example usage:
#      DEBUG=0 DMLC_PS_ROOT_PORT=12349 bash launch_byteps_comp.sh

export DMLC_NUM_WORKER=32
export DMLC_NUM_SERVER=16
# XXX: this cannot be hostname
export DMLC_PS_ROOT_URI=172.31.15.227
export DMLC_PS_ROOT_PORT="${DMLC_PS_ROOT_PORT:-12329}"
export COMMIT="${COMMIT:-d3ff4d453e}"

num_physical_server=16
server_hosts=server_16
worker_hosts=worker_32

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
export BYTEPS_FORCE_DISTRIBUTED=1


COMMON_ENV="export DMLC_NUM_WORKER=$DMLC_NUM_WORKER; \
            export DMLC_NUM_SERVER=$DMLC_NUM_SERVER; \
            export DMLC_PS_ROOT_URI=$DMLC_PS_ROOT_URI; \
            export DMLC_PS_ROOT_PORT=$DMLC_PS_ROOT_PORT;"

SERVER_ENV="$COMMON_ENV \
            export SERVER_PUSH_NTHREADS=$SERVER_PUSH_NTHREADS; \
            export MXNET_OMP_MAX_THREADS=$MXNET_OMP_MAX_THREADS; \
            export MXNET_CPU_WORKER_NTHREADS=$MXNET_CPU_WORKER_NTHREADS;"

DOCKER="nvidia-docker run -v $HOME/.ssh:/root/.ssh -v $HOME/mxnet-data/bert-pretraining/datasets:/data -v $HOME/efs/haibin/45-nodes:/efs -v /fsx:/fsx --network=host --shm-size=32768m"
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
export DEBUG="${DEBUG:-1}"
WHOLE=0;
PHASE2=0;
DOCKER_DEBUG=0;
#BS=32768;
#ACC=2;
#BS=16384;
#ACC=1;
#BS=256;
#BS=64512;
#ACC=8;
BS=65536;
ACC=4;
LR=0.006;
#LR=0.007;
WARMUP_RATIO=0.2843;
#WARMUP_RATIO=0.3;
#NUMSTEPS=7032;
NUMSTEPS=7038;
NO_SHARD=0;

#LR=0.005;
#WARMUP_RATIO=0.2;
#NUMSTEPS=14063;

#LR=0.003535;
#WARMUP_RATIO=0.1;
#NUMSTEPS=28125;

MAX_SEQ_LENGTH=128
MAX_PREDICTIONS_PER_SEQ=20


#COMMIT="5fd3cf5a";
#COMMIT="3b10c803";
#COMMIT="2fad482d";
#COMMIT="00f8c51";
#COMMIT="9badb2e7";
CKPTDIR="/fsx/bert/$worker_docker/$COMMIT/64K-shuffle-norm-acc-4-real-shuffle"
CKPTDIR="/fsx/bert/$worker_docker/7d7a0122/64K-shuffle-norm-acc-8-whole"
#CKPTDIR="/fsx/bert/$worker_docker/59344c4/64K-shuffle-norm-acc-4-stage2-no-state"
CKPTDIR="/fsx/bert/$worker_docker/$COMMIT/64K-shard-no-manual-l2"
CKPTDIR="/fsx/bert/$worker_docker/2fad482d/64K-shard-circle-8"
CKPTDIR="/fsx/checkpoints/ckpt_stage1_lamb_64k_sz"
CKPTDIR="/fsx/bert/$worker_docker/$COMMIT/tf-64k-no-seed"
CKPTDIR="/fsx/test-hvd-npz-64k-32k-dup5-bps-phase2"
CKPTDIR="/fsx/bert/$worker_docker/$COMMIT/bps-tf-baseline-64k"

mkdir -p $CKPTDIR
sudo chmod 777 $CKPTDIR
echo "============" >> $CKPTDIR/launch.sh
cat launch_byteps_comp.sh >> $CKPTDIR/launch.sh

BPS_HOME=/usr/local/byteps

if [ "$DEBUG" == "1" ]; then
   export OPTIONS="--synthetic_data\ --eval_use_npz";
   export LOGINTERVAL=1;
else
   export DATA="/fsx/datasets/book-wiki-split-2k-v3/*.train,"
   export OPTIONS="--raw\ --eval_use_npz";
   export DATA="/fsx/datasets/generated-book-wiki-split-2k-v3-phase2-dup-5/*.npz,"
   export DATA="/fsx/datasets/generated-book-wiki-split-2k-v3-phase1-dup-5/*.npz,"
   export OPTIONS="--eval_use_npz";
   export LOGINTERVAL=10;
fi

if [ "$WHOLE" == "1" ]; then
    export OPTIONS="$OPTIONS\ --whole_word_mask";
fi
            #export DATAEVAL=/fsx/datasets/book-wiki-split-2k-v3/*.dev,; \

if [ "$PHASE2" == "1" ]; then
    export NUMSTEPS=7038;     # XXX hard coded
    export OPTIONS="$OPTIONS\ --phase2\ --phase1_num_steps=$NUMSTEPS\ --start_step=$NUMSTEPS"
    export NUMSTEPS=1564
    export BS=32768
    export ACC=16
    export ACC=64
    export LR=0.004
    export WARMUP_RATIO=0.128
    export WARMUP_RATIO=0.13
    export MAX_SEQ_LENGTH=512
    export MAX_PREDICTIONS_PER_SEQ=80
fi

WORKER_ENV="$COMMON_ENV \
            export BPS_HOME=$BPS_HOME; \
            export BYTEPS_LOG_LEVEL=DEBUG; \
            export BYTEPS_PARTITION_BYTES=$BYTEPS_PARTITION_BYTES; \
            export BYTEPS_NCCL_NUM_RINGS=$BYTEPS_NCCL_NUM_RINGS; \
            export BYTEPS_FORCE_DISTRIBUTED=$BYTEPS_FORCE_DISTRIBUTED; \
            export LOGINTERVAL=$LOGINTERVAL; \
            export BS=$BS; \
            export LR=$LR; \
            export MAX_SEQ_LENGTH=$MAX_SEQ_LENGTH; \
            export MAX_PREDICTIONS_PER_SEQ=$MAX_PREDICTIONS_PER_SEQ; \
            export NO_SHARD=$NO_SHARD; \
            export DATA=$DATA; \
            export DATAEVAL=/fsx/datasets/part-000.npz; \
            export REPEAT_SAMPLER=1; \
            export CIRCLE_LEN=1; \
            export SKIP_STATE_LOADING=1; \
            export PT_DECAY=0; \
            export NUM_DATA_THREAD=1; \
            export MANUAL_ACC=0; \
            export EVEN_SHUFFLE=0; \
            export SKIP_GLOBAL_CLIP=0; \
            export SCALE_NORM=0; \
            export L1_NORM=0; \
            export USE_BOUND=0; \
            export ADJUST_BOUND=0; \
            export OPTIONS=$OPTIONS; \
            export OPTIMIZER=lamb2; \
            export WARMUP_RATIO=$WARMUP_RATIO; \
            export NUMSTEPS=$NUMSTEPS; \
            export CKPTDIR=$CKPTDIR; \
            export ACC=$ACC; "

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
