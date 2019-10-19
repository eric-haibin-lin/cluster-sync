HOST=~/hosts_np256_clush
HOST=~/hosts_np256_clush_other
DOCKER_IMAGE=haibinlin/worker_mxnet:c5fd6fc-1.5-cu90-cd9d391d-ccb5a695
PORT=12444
PORT2=12448

#clush --hostfile $HOST "ls ~/efs"

#clush --hostfile $HOST "docker pull $DOCKER_IMAGE"

#clush --hostfile $HOST "ls ~/ssh_info;"

#clush --hostfile $HOST "sudo chmod 777 ~/ssh_info"
#clush --hostfile $HOST 'docker kill $(docker ps -q);'

#clush --hostfile $HOST "docker ps";
clush --hostfile $HOST "docker ps --no-trunc";

exit
GENERATED_DIR=~/haibin/generated

clush --hostfile $HOST "sudo rm -rf ~/ssh_info; cp -r ~/.ssh ~/ssh_info;"
clush --hostfile $HOST "nvidia-docker run -d --security-opt seccomp:unconfined --privileged  \
                 -v ~/ssh_info:/root/.ssh  \
                 -v /home/ubuntu/mxnet-data/bert-pretraining/datasets:/data          \
                 -v $GENERATED_DIR:/generated                               \
                 --network=host --shm-size=32768m --ulimit nofile=65536:65536 $DOCKER_IMAGE   \
                 bash -c 'bash hvd_ssh.sh; /usr/sbin/sshd -p $PORT2 -d 2>&1 | tee -a ssh_log'"
