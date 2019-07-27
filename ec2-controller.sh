#!/bin/bash
if [ $# -ne 2 ]; then
    echo 'usage: ';
    echo 'bash ec2-controller.sh instance-name default';
    exit -1;
fi

PROFILE=$2
mkdir -p ~/hosts

aws --profile $PROFILE --output text ec2 describe-instances --filters "Name=tag:Name,Values=$1" --query "Reservations[*].Instances[*].[PrivateIpAddress]" > ~/hosts/$1
aws --profile $PROFILE --output text ec2 describe-instances --filters "Name=tag:Name,Values=$1" --query "Reservations[*].Instances[*].[PublicIpAddress]" > ~/hosts/$1.public
hudl -v -h ~/hosts/$1 -c ~/hosts/$1 -d /home/ubuntu/hosts;
