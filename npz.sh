#!/bin/bash

if [ $# -le 3 ]; then
    echo 'usage: ';
    echo 'bash npz.sh /fsx/datasets/webtext/webtext-split/*.train,/fsx/datasets/enwiki/enwiki-feb-doc-split/*.train /fsx/datasets/generated/web-book-enwiki/web-book-enwiki-sp-uncased 10 py36 /fsx/datasets/vocab/webtext-book-wiki/webtext_book_wiki_uncased_bpe_30k_sampled_20M.model';
    echo "number of arguments received = $#";
    exit -1;
fi

export DATA=$1
export OUT=$2
export DUPE=$3
export PY_VERSION=$4
export SPM=$5

if [ $PY_VERSION = 'py27' ]; then
  export PY='python27';
elif [ $PY_VERSION = 'py36' ]; then
  export PY='python36';
fi

for (( i=0; i<$DUPE; i++ ))
do
    if [ "$SPM" = "" ]; then
        $PY create_pretraining_data.py \
        --input_file $DATA \
        --output_dir $OUT/part-$i/ \
        --num_outputs 99999 --num_workers 128 --random_seed $i
    else
        $PY create_pretraining_data.py \
        --input_file $DATA \
        --output_dir $OUT/part-$i/ \
        --sentencepiece $SPM \
        --num_outputs 99999 --num_workers 128 --random_seed $i
    fi
done