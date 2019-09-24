mpirun -np 8 --allow-run-as-root -x NCCL_MIN_NRINGS=8 -x NCCL_DEBUG=INFO \
       -x HOROVOD_HIERARCHICAL_ALLREDUCE=1 -x HOROVOD_CYCLE_TIME=1 \
       -x MXNET_EXEC_BULK_EXEC_MAX_NODE_TRAIN=120 -x MXNET_SAFE_ACCUMULATION=1 \
       --tag-output python /opt/gluon-nlp/scripts/bert/run_pretraining_hvd.py \
       '--data=/data/language_modeling/book-corpus-large-split/*.train,/data/language_modeling/enwiki-feb-doc-split/*.train' \
       '--data_eval=/data/language_modeling/book-corpus-large-split/*.test,/data/language_modeling/enwiki-feb-doc-split/*.test' \
       --num_steps 10000 --lr 1e-4 --batch_size 4096 --accumulate 4 --use_avg_len --no_compute_acc --raw
