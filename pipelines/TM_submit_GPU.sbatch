#!/bin/bash
#SBATCH --mem 200G
#SBATCH -p gpu-el8
#SBATCH -N 1
#SBATCH -t 48:00:00
##SBATCH -C gpu=A100
#SBATCH --gres=gpu:1
#SBATCH --export=NONE
#SBATCH --exclude=gpu[10-15],gpu[21-28],gpu[29-39]

# To load the pytom environment:
module load PyTom/1.0b-foss-2021a-CUDA-11.3.1
echo $CUDA_VISIBLE_DEVICES

/usr/bin/time -v mpirun -c 1 ` which localization.py ` -g $CUDA_VISIBLE_DEVICES -j TM_job.xml

