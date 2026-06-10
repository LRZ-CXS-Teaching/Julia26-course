#!/bin/bash

#---------- recommended section ----------
#SBATCH --mail-type=NONE                # RECOMMENDED: NONE (avoid mess); which notifications you want to be sent to your mail
#SBATCH --export=ALL                    # RECOMMENDED: NONE or ALL; do you want to export any env var from your shell?
#SBATCH --get-user-env                  # RECOMMENDED; source the ~/.bash_profile etc of the user
#SBATCH --requeue                       # RECOMMENDED; automatically requeue in case of node fail (happens sometimes)
#SBATCH --qos=normal                    # -q    # quality of service

#---------- customizable section  ----------
#SBATCH --account=def-sponsor00         # -A    # your project ID, NOT YOUR ACCOUNT
#SBATCH --partition=node-small          # -p    # partition name
#SBATCH --time=00:10:00                 # -t    # maximum time; valid formats: MM, MM:SS, HH:MM:SS, dd-HH, dd-HH:MM , dd-HH_MM:SS
#
#SBATCH --nodes=1                       # -N    # nodes requested
##SBATCH --ntasks=...                   # -n    # num tasks to run (default 1 task per node)
#SBATCH --ntasks-per-node=2                     # RECOMMENDED: #mpi tasks per node (or 1)
#SBATCH --cpus-per-task=1                       # RECOMMENDED: 1 (or #cores physical of worker CPUs)
#SBATCH --chdir=.                       # -D    # working director
#
#SBATCH --job-name=test                 # -J    # job name (default: executable program name)
#SBATCH --output=./%j_%x.out            # -o    # CHECK THAT ITS DIR EXIST!
#SBATCH --error=./%j_%x.err             # -e    # CHECK THAT ITS DIR EXIST!

# 1. load underlying cluster/EESSI MPI environment
module load OpenMPI/4.1.6-GCC-13.2.0

# 2. load julia
module load julia/1.12.6

# 3. execute MPI job via cluster launcher
mpiexec -n $SLURM_NTASKS --bind-to core julia -- ~/mpi-hello-world.jl

