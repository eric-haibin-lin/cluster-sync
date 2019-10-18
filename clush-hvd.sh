
DOCKER_IMAGE=haibinlin/worker_mxnet:c5fd6fc-1.5-cu90-cd9d391d-ccb5a695

clush --hostfile $HOST "ls ~/efs"

clush --hostfile $HOST "docker pull $DOCKER_IMAGE"

exit

clush --hostfile $HOST "nvidia-docker run -d --security-opt seccomp:unconfined --privileged  \
                 -v ~/ssh_info:/root/.ssh  \
                 -v /home/ubuntu/mxnet-data/bert-pretraining/datasets:/data          \
                 -v /home/ubuntu/efs/haibin:/generated                               \
                 --network=host --shm-size=32768m $DOCKER_IMAGE                 \
                 bash -c 'bash hvd_ssh.sh; /usr/sbin/sshd -p $PORT -d'"
