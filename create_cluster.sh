sudo sh -c "curl https://raw.githubusercontent.com/eric-haibin-lin/hudl/master/hudl -o /usr/local/bin/hudl && chmod +x /usr/local/bin/hudl"


export HOSTS=~/hosts/haibin-bert-cased-large-baseline;

hudl -v -h $HOSTS -c $HOSTS -d ~/hosts;

hudl -t -v -h $HOSTS -d ~ -s dependency.sh eric-haibin-lin raw mxnet-cu90==1.5.0b20190525 mx-0525-raw-large-cased 2177746 90 py27;

hudl -h $HOSTS -v 'cat .status';

export MASTER=$(head -n 1 $HOSTS)

ssh $MASTER ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

export PUBKEY=$(ssh $MASTER 'cat .ssh/id_rsa.pub');
hudl -h $HOSTS "echo $PUBKEY >> ~/.ssh/authorized_keys";

hudl -h $HOSTS -v 'cat ~/.ssh/authorized_keys';