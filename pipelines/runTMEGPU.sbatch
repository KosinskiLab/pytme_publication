#!/bin/bash
#SBATCH --mem 200G
#SBATCH -p gpu-el8
#SBATCH -N 1
#SBATCH -t 48:00:00
##SBATCH -C gpu=A100
#SBATCH --gres=gpu:1
#SBATCH --export=NONE
#SBATCH --exclude=gpu[10-15],gpu[21-28],gpu[29-39]

source $HOME/.bashrc
conda activate dge
echo $CUDA_VISIBLE_DEVICES
module load CUDA/12.2.0

TOMOGRAM_PATH="/scratch/vmaurer/templateMatchingLibrary/data/stopgapBase/maps/002.rec"
TOMOGRAM_TEMPLATE="/scratch/vmaurer/templateMatchingLibrary/data/stopgapBase/tmpl/template.mrc"
TOMOGRAM_TEMPLATE_MASK="/scratch/vmaurer/templateMatchingLibrary/data/stopgapBase/masks/mask.mrc"
ANGULAR_SAMPLING=8

/usr/bin/time -v match_template.py \
    -m $TOMOGRAM_PATH \
    -i $TOMOGRAM_TEMPLATE \
    --template_mask $TOMOGRAM_TEMPLATE_MASK \
    --cutoff_template 0 \
    -s FLCSphericalMask \
    -n 1 \
    --use_gpu \
    -r 1000000000000000 \
    --no_edge_padding \
    -a $ANGULAR_SAMPLING