#!/bin/bash
#SBATCH --mem 100G
#SBATCH -p gpu-el8
#SBATCH -N 1
#SBATCH -t 0:30:00
#SBATCH -C gpu=3090
#$BATCH --qos=highest
#SBATCH --gres=gpu:2
#SBATCH --export=NONE

source $HOME/.bashrc
conda activate dge
echo $CUDA_VISIBLE_DEVICES
module load CUDA/12.2.0
echo "multi"
TOMOGRAM_PATH="/scratch/vmaurer/mycoplasma_data/tomos/imod_tomograms/00032b4_inverted.mrc"
TOMOGRAM_TEMPLATE="/scratch/vmaurer/mycoplasma_data/references/RNApol_bin4.mrc"
ANGULAR_SAMPLING=15

/usr/bin/time -v match_template.py \
    -m $TOMOGRAM_PATH \
    -i $TOMOGRAM_TEMPLATE \
    --cutoff_template 0 \
    -s CORR \
    -n 1 \
    --use_gpu \
    -a $ANGULAR_SAMPLING \
    --no_edge_padding \
    --no_fourier_padding \
    -o bin8.pickle
