#!/bin/bash
#SBATCH --mem 200G
#SBATCH -p gpu-el8
#SBATCH -N 1
#SBATCH -t 0:30:00
#SBATCH -C gpu=A100
#SBATCH --gres=gpu:1
#SBATCH --export=NONE
#SBATCH --exclude=gpu[10-15],gpu[21-28],gpu[29-39]

source $HOME/.bashrc
conda activate dge
echo $CUDA_VISIBLE_DEVICES
module load CUDA/12.2.0

TOMOGRAM_PATH="/scratch/vmaurer/mycoplasma_data/tomos/imod_tomograms/00032b8_inverted.mrc"
TOMOGRAM_TEMPLATE="/scratch/vmaurer/mycoplasma_data/references/RNApol_bin8.mrc"
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
