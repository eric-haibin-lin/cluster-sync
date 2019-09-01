num_worker=4
num_physical_server=4
num_server=12
root_ip=172.32.37.101
server_hosts=server_4
# server_hosts=worker_4
worker_hosts=worker_4

# net=bert_24_1024_16
# batch_size=12

byte_part_size=4096000
byte_num_rings=1
byte_num_groups=4
byte_pcie=8
byte_push=1
byte_omp=1
byte_cpu=1
byte_load_balance=2


server_docker=haibinlin/server:3
worker_docker=haibinlin/worker:7

# cleanup
# hudl -h $server_hosts "docker pull $server_docker"
hudl -h $server_hosts 'sudo pkill python'
# hudl -h $worker_hosts "docker pull $worker_docker"
hudl -h $worker_hosts 'sudo pkill python3'

# scheduler
nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c "cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip  1234 scheduler $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu"

num_server_iter=0
target_server_iter=$num_server/$num_physical_server
while true;
do
  if [[ $num_server_iter -ge $target_server_iter ]]
  then
    break
  fi
  hudl -h $server_hosts -t "nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip  1234 server $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu'"
  echo "launched $num_physical_server servers: nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip  1234 server $byte_part_size $byte_num_rings $byte_num_groups $byte_push $byte_omp $byte_cpu'"
  let "num_server_iter+=1"
done;

count=0
while read -u 10 host;
do
  host=${host%% slots*}
  echo "nvidia-docker run --security-opt seccomp=seccomp.json -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $worker_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip 1234 worker $count bert_24_1024_16 12 $byte_part_size $byte_num_rings $byte_num_groups $byte_pcie $byte_load_balance' on $host"
  ssh -o "StrictHostKeyChecking no" $host tmux new-session -d "nvidia-docker run --security-opt seccomp=seccomp.json -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $worker_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh $num_server $num_worker $root_ip 1234 worker $count bert_24_1024_16 12 $byte_part_size $byte_num_rings $byte_num_groups $byte_pcie $byte_load_balance'"
  let "count+=1"
done 10<$worker_hosts;
