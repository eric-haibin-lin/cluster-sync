# task: MNLI
export TASK=MNLI
# typically 16, 32
export BS=16
# typically 3, 4
export EPOCH=4
# typically 1e-5, 2e-5, 5e-5
export LR=5e-5

export GPU=0
export SEED=0
export NAME=test-run

export BUCKET=s3://bert-pretraining
export CKPT=$BUCKET/experiment/0316/8x-sqrt-8x-warmup-8x/0125000.params
export CONFIG=$TASK-$ESP-$BS-$EPOCH-$LR-$SEED-len-512
export FULL_NAME=$NAME-$CONFIG
export SCRIPT=scripts/bert/finetune_classifier.py

export CMD="python $SCRIPT --task_name $TASK --log_interval 100 --batch_size $BS --epochs $EPOCH --gpu $GPU --lr $LR --seed $SEED --max_len 512 2>&1 result.log"

python submit-job.py --source-ref master --remote https://github.com/dmlc/gluon-nlp --name $FULL_NAME --save-path batch/temp/$FULL_NAME --conda-env gpu/py3-master --command "$CMD"






