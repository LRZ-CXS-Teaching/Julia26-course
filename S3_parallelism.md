# Parallelism-related Topics and Patterns

## Overview - Types of Parallelism

There are many different possibilities to parallelize workflows on classical CPUs. 

The CPU itself exposes already some of them like wide *vector registers* (SSE, AVX, AVX2, AVX512; much like GPUs), but also pipelining (and out of order execution). 

A CPU nowadays has several CPU cores, which might share different levels of caches (L1I/L1D, L2, L3, ...). Sitting on the same L1 cache, mostly 2, less often 4, such cores simply represent multiplication of the instruction pipeline. We'll call those *hardware threads* or *hyper-threads* - the operating system (OS) calls them often *logical CPUs*. In contrast, all hyper-threads belonging together, are called *physical CPUs*.

Physical CPU cores sharing a common *last-level cache* (LLC) usually sit together on a NUMA (*n*on-*u*niform *m*emory *a*ccess) domain, meaning that they still have access to the same memory infra-structure (memory bus) - though access speed might differ.

Finally, there might be one or two (or, rarely more) such NUMA domains on a socket (interconnected e.g. by a QPI == *q*uick-*p*ath *i*nterconnect). And a computer might possess one or more sockets on a board.

<br>

On those cores, the OS distributes processes and threads. The latter usually sort of "low-budget processes", attached together in a process structure (parent/child). The OS must choose the locations (the specific CPU core), where the processes and threads run on. Users can usually also determine that - within limits.

If two threads/processes run on the same CPU, the OS gives them a time slot where they can run. After that period, the OS stops the process/thread, saves the related cache and state data, and then brings in the next process filling the cache and pipeline. This is called a *context switch*. And such processes only appear to us to run in parallel. In fact, they don't. They are only *multiplexed*. This type of "parallelism", most programmers call *concurrency*, sparing the term *parallel* really only for processes running contemporarily (independently at the same time) on different CPUs.

It is hopefully immediately clear that concurrency in that sense actually means sharing of resources, which is already due to the context switching very inefficient. And thus, that's not desirable for HPC. One should be carefully check the placement of processes and threads, therefore. It has a really strong performance impact.

<br>

We will look at the following programming models for parallelism, how they can be employed in Julia.

- simd / vectorization
- threads
- parallel workers and task-parallelism
- message passing

## SIMD (Vectorization)

## Threads
`JULIA_EXCLUSIVE=1 julia --threads 4 prog.jl`

## Task-Parallelism (distributed, pmap)

## MPI (Message Passing Interface)

