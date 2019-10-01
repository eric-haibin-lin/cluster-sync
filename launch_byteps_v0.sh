num_worker=1
num_physical_server=1
num_server=1
# this cannot be hostname
root_ip=172.31.83.92
root_port=1234
server_hosts=server_0
worker_hosts=worker_0

net=bert_24_1024_16
batch_size=1

byte_part_size=4096000
byte_num_rings=12
byte_num_groups=8
byte_pcie=8
byte_push=1
byte_omp=1
byte_cpu=1
byte_load_balance=1
# credit_size=$byte_num_groups + 1
credit_size=0
async=0
timeline=0

server_docker=haibinlin/py3-gluon-server:0
worker_docker=haibinlin/worker:109

# cleanup
hudl -v -h $server_hosts 'sudo pkill python'
hudl -v -h $worker_hosts 'sudo pkill python'

# scheduler
nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c "cd gluon-nlp/scripts/bert/; bash bps_server.sh $num_server $num_worker $root_ip  $root_port scheduler $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu $async 0"

num_server_iter=0
target_server_iter=$num_server/$num_physical_server
while true;
do
  if [[ $num_server_iter -ge $target_server_iter ]]
  then
    break
  fi
  hudl -h $server_hosts -t -v "nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c 'cd gluon-nlp/scripts/bert/; bash bps_server.sh $num_server $num_worker $root_ip  $root_port server $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu $async $timeline'"
  echo "launched $num_physical_server servers: nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c 'cd gluon-nlp/scripts/bert/; bash bps_server.sh $num_server $num_worker $root_ip  $root_port server $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu $async $timeline'"
  let "num_server_iter+=1"
done;

count=0
while read -u 10 host;
do
  host=${host%% slots*}
  echo "nvidia-docker run --security-opt seccomp=seccomp.json -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $worker_docker bash -c 'cd gluon-nlp/scripts/bert/; bash bps_worker.sh $num_server $num_worker $root_ip $root_port worker $count $net $batch_size $byte_part_size $byte_num_rings $byte_num_groups $byte_pcie $byte_load_balance $credit_size $async 0 byteps' on $host"
  ssh -o "StrictHostKeyChecking no" $host tmux new-session -d "nvidia-docker run --security-opt seccomp=seccomp.json -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $worker_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip $root_port worker $count $net $batch_size $byte_part_size $byte_num_rings $byte_num_groups $byte_pcie $byte_load_balance $credit_size $async 0 byteps'"
  let "count+=1"
done 10<$worker_hosts;
