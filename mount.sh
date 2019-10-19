echo '==================== installing lustre client ...  ==================== ';
sudo yum -q install -y lustre-client;

#sudo apt-get install -y linux-image-4.4.0-131-generic
#sudo apt-get install -y linux-headers-4.4.0-131-generic

#wget -o lustre-client-modules-4.4.0-131-generic_2.10.6-1_amd64.deb https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/ubuntu1604/client/lustre-client-modules-4.4.0-131-generic_2.10.6-1_amd64.deb
#wget -o lustre-utils_2.10.6-1_amd64.deb https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/ubuntu1604/client/lustre-utils_2.10.6-1_amd64.deb
#sudo apt-get install -y ./lustre-*_2.10.6*.deb


wget -o az_info -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O az_info;
AZ_ID=$(cat az_info);
echo "==================== instance is in $AZ_ID  ==================== "

if [ "$AZ_ID" = "us-east-1f" ];
  then export TARGET="fs-084c657c236d54fe0.fsx.us-east-1";
fi
if [ "$AZ_ID" = "us-east-1c" ];
  then export TARGET="fs-045cd4d6c1f50763b.fsx.us-east-1";
fi
if [ "$AZ_ID" = "us-east-1a" ];
  then export TARGET="fs-05ab0ecd72b621dee.fsx.us-east-1";
fi
if [ "$AZ_ID" = "us-east-1b" ];
  then export TARGET="fs-084c3f84f1f190407.fsx.us-east-1";
fi
if [ "$AZ_ID" = "us-west-2a" ];
  then export TARGET="fs-0120f6fc2761a74c9.fsx.us-west-2";
fi
if [ "$AZ_ID" = "us-west-2c" ];
  then export TARGET="fs-035ee27f2918a879d.fsx.us-west-2";
fi
if [ "$TARGET" = "" ];
  then echo "No lustre file system found for region $AZ_ID"; exit -1;
fi
echo "==================== mount $TARGET lustre file system ... ====================";
sudo mkdir -p /fsx;
sudo mount -t lustre $TARGET.amazonaws.com@tcp:/fsx /fsx;
sudo chmod a+w /fsx;
