#!/bin/bash
#SBATCH --mem 350G
#SBATCH -p gpu-el8
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -C gpu=A100
#SBATCH --gres=gpu:1
#SBATCH --export=NONE
#SBATCH --qos=highest
##SBATCH --exclude=gpu[10-15],gpu[21-28],gpu[29-39]

source $HOME/.bashrc
conda activate dge
echo $CUDA_VISIBLE_DEVICES
module load CUDA/12.2.0

TOMOGRAM_PATH="/scratch/vmaurer/mycoplasma_data/tomos/imod_tomograms/00032b1_inverted.mrc"
TOMOGRAM_TEMPLATE="/scratch/vmaurer/mycoplasma_data/references/RNApol_bin1.mrc"
ANGULAR_SAMPLING=60

echo $TMPDIR
mprof run match_template.py \
    -m $TOMOGRAM_PATH \
    -i $TOMOGRAM_TEMPLATE \
    --cutoff_template 0 \
    -s CORR \
    -n 1 \
    --use_gpu \
	-r 30000000000 \
    -a $ANGULAR_SAMPLING \
    --no_edge_padding \
    --no_fourier_padding \
    -o /scratch/vmaurer/temp/bin1_2.pickle \
	--use_mixed_precision \
	--temp_dir $TMPDIR \
	--use_memmap
