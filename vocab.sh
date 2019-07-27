#!/bin/bash

if [ $# -le 0 ]; then
    echo 'usage: ';
    echo 'bash vocab.sh xx.cat';
    echo "number of arguments received = $#";
    exit -1;
fi

TARGET=$1

cat $TARGET | sed -e 's/\(.*\)/\L\1/' > $TARGET.lower


# python code below:
# import sentencepiece as sp
# sp.SentencePieceTrainer.Train(--input=/home/ec2-user/enwiki.cat.lower,/home/ec2-user/webtext.cat.lower,/home/ec2-user/book.cat.lower --model_prefix=webtext-cased-30k-sampled-40M --vocab_size=30000 --model_type=BPE --max_sentence_length=80000 --num_threads=48 --input_sentence_size=20000000 --shuffle_input_sentence=true)

# split -b 32MB -d wikitalk-reddit-dialog.cat wikitalk-reddit-dialog-part-