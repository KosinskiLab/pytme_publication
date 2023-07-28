#! /usr/bin/env bash
set -e              # Crash on error
set -o nounset      # Crash on unset variables

## run_stopgap.sh
# A script for performing subtomogram averaging using 'stopgap'.
# This script first generates a submission file and then launches
# 'stopgap_watcher', a MATLAB executable that manages the flow of parallel
# stopgap averging jobs.
#
# This specific script was written for clusters at the MPI Biochemistry.
# Use this an example for your specific cluster.
#
# WW 06-2018



##### RUN OPTIONS #####
#scripts_path="/g/kosinski/ziemianowicz/software/tomo_sa/stopgap/exec"		# to export proper path - either 'cryo' or 'local'
run_type='slurm'            # Types supported are 'local', 'sge', and 'slurm', for local, SGE-cluster and slurm-cluster submissions.
n_cores=24                # Number of subtomogram alignment cores
mem_limit=64G             # Amount of memory per node (G = gigabytes). Ignored for local jobs.
time_limit='80:00:00'            # Maximum run time in seconds (max = 604800 seconds). Ignored for local jobs.
job_id=311561

special_add="-p ib --qos=normal"			# e.g. --qos=high

##### DIRECTORIES #####
local_folder="$(pwd)/comm/"

rootdir="$(pwd)/"    # Main subtomogram averaging directory
paramfilename='tm_param.star'          # Relative path to stopgap parameter file.


#### Modules ####
matlab_module="MATLAB/2016b.Update_7"
#openmpi_module="foss/2020b"


################################################################################################################################################################
##### SUBTOMOGRAM AVERAGING WORKFLOW                                                                                                       ie. the nasty bits...
################################################################################################################################################################

#module load ${matlab_module}
module load STOPGAP/0.7.1-foss-2020b-MCR-R2016b
#export STOPGAPHOME=$scripts_path

echo ${STOPGAPHOME}

# Path to MATLAB executables
watcher="${STOPGAPHOME}/bin/stopgap_watcher.sh"
subtomo="${STOPGAPHOME}/bin/stopgap_mpi_slurm.sh"


# Remove previous submission script
rm -f submit_stopgap_${job_id}

if [ "${run_type}" = "local" ]; then
    echo "Running stopgap locally..."

    # Local submit command
    submit_cmd="mpiexec -np ${n_cores} ${subtomo} ${rootdir} ${paramfilename} ${n_cores}  2> ${rootdir}/error_stopgap 1> ${rootdir}/log_stopgap &"
    # echo ${submit_cmd}

elif [ "${run_type}" = "slurm" ]; then
    echo "Preparing to run stopgap on slurm-cluster..."

    # Write submission script
    echo '#!/bin/bash' > submit_stopgap_${job_id}
    echo "#SBATCH -D ${rootdir}" >> submit_stopgap_${job_id}
    echo "#SBATCH -e err_${job_id}-%j" >> submit_stopgap_${job_id}
    echo "#SBATCH -o log_${job_id}-%j" >> submit_stopgap_${job_id}
    echo "#SBATCH --job-name ${job_id}" >> submit_stopgap_${job_id}
    echo "#SBATCH -n ${n_cores}" >> submit_stopgap_${job_id}
    echo "#SBATCH --mem ${mem_limit}" >> submit_stopgap_${job_id}
    #echo "#SBATCH --mem-per-cpu=${mem_limit}" >> submit_stopgap_${job_id}
    echo "#SBATCH --time=${time_limit}" >> submit_stopgap_${job_id}
    echo "#SBATCH -C "znver3x"" >> submit_stopgap_${job_id}
	echo "" >> submit_stopgap_${job_id}

	echo "module purge" >> submit_stopgap_${job_id}
	echo "" >> submit_stopgap_${job_id}

	echo "module load STOPGAP/0.7.1-foss-2020b-MCR-R2016b" >> submit_stopgap_${job_id}
	echo "" >> submit_stopgap_${job_id}

	echo "mpirun ${subtomo} ${rootdir} ${paramfilename} ${n_cores}" >> submit_stopgap_${job_id}

	# Make executable
    chmod +x submit_stopgap_${job_id}

    # Submission command
    sbatch ${special_add} submit_stopgap_${job_id}

else
    echo 'ACHTUNG!!! Invalid run_type!!!'
    echo 'Only supported run_types are "local", "sge", and "slurm"!!!'
    exit 1
fi


exit

