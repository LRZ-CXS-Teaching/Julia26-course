# RedLion slurm cluster


1. Subscribe here: <https://mokey.red-lion.gcs-devcloud.hpc.lrz.de/auth/login>
2. wait for an admin to approve you
3. login via ssh

```bash
$ ssh <username>@138.246.237.46
    # paste the password you set before in the form
```

<br>


Here we show some basic commands to interact with the RedLion cluster via slurm.

Get an interactive 10-min session on a gpu node:

```bash
$ salloc -p gpu-node --gres=gpu:1 -A def-sponsor00 -t 10 --mem 0
$ module load julia
```

<br>

Submit an MPI job interactively:

```bash
$ salloc -p node -N 2 -A def-sponsor00 -t 30 --mem 0
$ module load julia
$ module load OpenMPI/4.1.6-GCC-13.2.0
$ mpiexec -n 2 julia -- ./mpi-hello-world.jl
```

<br>

Submit an MPI job via sbatch:

```bash
# edit the ./mpi.sh and ./mpi-hello-world.jl files as you wish
$ sbatch mpi.sh
```
