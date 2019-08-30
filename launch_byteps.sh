num_worker=31
num_physical_server=31
num_server=93
root_ip=172.32.37.101
#server_hosts=server_31
server_hosts=worker_32
worker_hosts=worker_32

# net=bert_24_1024_16
# batch_size=12

byte_part_size=4096000
byte_num_rings=12
byte_num_groups=4
byte_omp=1
byte_pcie=8
byte_push=1
byte_cpu=1


server_docker=haibinlin/server:1
worker_docker=haibinlin/worker:4

# cleanup
#hudl -h $server_hosts "docker pull $server_docker"
hudl -h $server_hosts 'sudo pkill python'
#hudl -h $worker_hosts "docker pull $worker_docker"
hudl -h $worker_hosts 'sudo pkill python3'

# scheduler
nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c "cd gluon-nlp/scripts/bert/; bash byteps.sh 8 $num_server $num_worker $root_ip  1234 scheduler 0 bert_24_1024_16 12 $byte_part_size $byte_num_rings $byte_num_groups"

num_server_iter=0
target_server_iter=$num_server/$num_physical_server
while true;
do
  if [[ $num_server_iter -ge $target_server_iter ]]
  then
    break
  fi
  hudl -h $server_hosts -t "nvidia-docker run -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $server_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh 8 $num_server $num_worker $root_ip  1234 server 0 bert_24_1024_16 12 $byte_part_size $byte_num_rings $byte_num_groups $byte_omp'"
  echo "launched $num_physical_server servers"
  let "num_server_iter+=1"
done;

count=0
while read -u 10 host;
do
  host=${host%% slots*}
  ssh -o "StrictHostKeyChecking no" $host tmux new-session -d "nvidia-docker run --security-opt seccomp=seccomp.json -d -v ~/.ssh:/root/.ssh --network=host --shm-size=32768m $worker_docker bash -c 'cd gluon-nlp/scripts/bert/; bash byteps.sh 8 $num_server $num_worker $root_ip 1234 worker $count bert_24_1024_16 12 $byte_part_size $byte_num_rings $byte_num_groups $byte_pcie $byte_push $byte_cpu'"
  let "count+=1"
done 10<$worker_hosts;
