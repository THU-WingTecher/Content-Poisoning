#!/bin/bash

#!/bin/bash

export WANDB_MODE=disabled
# export CUDA_VISIBLE_DEVICES=0,1,2,3
# Optionally set the cache for transformers
# export TRANSFORMERS_CACHE='YOUR_PATH/huggingface'

export model=$1 # llama2 or vicuna
export setup=$2 # behaviors or strings


timestep=`date +%Y-%m-%d-%H:%M:%S`

last_file="./results/${setup}_${model}_${timestep}"
new_file=$last_file
if [ $# -eq 3 ]; then
    last_file=$3
    if [ ! -d $last_file ]; then
        echo "dir $last_file not found"
        exit 1
    fi
    new_file=${last_file}
    last_file=`echo "${last_file}" | sed 's|\(.*\)/.*|\1|'`
    last_file=${last_file}_1
    echo "last_file: $last_file, new_file: $new_file"
    cp -r $new_file ${last_file}
fi
# for data_offset in 0 10 20 30 40 50 60 70 80 90   # control the begin of train data in csv file, use this can evaluate on all train data with 10 data per time.
# for data_offset in 0
# do
lines=`cat ./data/${setup}.csv | egrep -v '^\s*$' | wc -l`

lines=$[lines-1]

echo total $lines goals


# echo "\n\n" > $last_file/log.txt

for data_offset in $(seq 0 1 $[lines-1])
do
    if [ -f "$new_file/attack_${data_offset}_succ.json" ]; then
        echo "skip $data_offset"
        echo "skip $data_offset" > $new_file/log.txt
        continue
    fi
    if [ -f "$new_file/attack_${data_offset}_fail.json" ]; then
        echo "skip $data_offset"
        echo "skip $data_offset" > $new_file/log.txt
        continue
    fi

    python -u ./main.py \
        --config="./configs/${model}.py" \
        --config.attack=gcg \
        --config.train_data="./data/${setup}.csv" \
        --config.result_prefix=$new_file \
        --config.n_train_data=1 \
        --config.stop_on_success=True \
        --config.data_offset=$data_offset \
        --config.n_steps=500 \
        --config.test_steps=50 \
        --config.batch_size=32, \
        --config.control_init="! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !" \
        --config.dynamic_pos=True \,
        --config.max_rand_pos=60
    sleep 1
done

# done
