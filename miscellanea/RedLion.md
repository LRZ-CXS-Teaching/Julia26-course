# RedLion slurm cluster

Here we show some basic commands to interact with the RedLion cluster via slurm.

Get an interactive 10-min session on a gpu node:

```bash
salloc -p gpu-node --gres=gpu:1 -A def-sponsor00 -t 10 --mem 0
module load
```

<br>

Submit an MPI job interactively:

```bash
salloc -p node -N 2 -A def-sponsor00 -t 30 --mem 0
module load julia
module load OpenMPI/4.1.6-GCC-13.2.0
mpiexec -n 2 julia -- ./mpi-hello-world.jl
```

<br>

Submit an MPI job via sbatch:

```bash
# edit the mpi.sh and mpi-hello-world.jl files as you wish
sbatch mpi.sh
```
