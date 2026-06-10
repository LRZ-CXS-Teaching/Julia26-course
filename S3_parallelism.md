# Parallelism-related Topics and Patterns

## Overview 

### Types of Parallelism in a Computer

There are many different possibilities to parallelize workflows on classical CPUs. 

The CPU itself exposes already some of them like wide *vector registers* (SSE, AVX, AVX2, AVX512; much like GPUs), but also pipelining (and out of order execution). 

A CPU nowadays has several CPU cores, which might share different levels of caches (L1I/L1D, L2, L3, ...). Sitting on the same L1 cache, mostly 2, less often 4, such cores simply represent multiplication of the instruction pipeline. We'll call those *hardware threads* or *hyper-threads* - the operating system (OS) calls them often *logical CPUs*. In contrast, all hyper-threads belonging together, are called *physical CPUs*.

Physical CPU cores sharing a common *last-level cache* (LLC) usually sit together on a NUMA (*n*on-*u*niform *m*emory *a*ccess) domain, meaning that they still have access to the same memory infra-structure (memory bus) - though access speed might differ.

Finally, there might be one or two (or, rarely more) such NUMA domains on a socket (interconnected e.g. by a QPI == *q*uick-*p*ath *i*nterconnect). And a computer might possess one or more sockets on a board.

<br>

On those cores, the OS distributes processes and threads. The latter usually sort of "low-budget processes", attached together in a process structure (parent/child). The OS must choose the locations (the specific CPU core), where the processes and threads run on. Users can usually also determine that - within limits.

If two threads/processes run on the same CPU, the OS gives them a time slot where they can run. After that period, the OS stops the process/thread, saves the related cache and state data, and then brings in the next process filling the cache and pipeline. This is called a *context switch*. And such processes only appear to us to run in parallel. In fact, they don't. They are only *multiplexed*. This type of "parallelism", most programmers call *concurrency*, sparing the term *parallel* really only for processes running contemporarily (independently at the same time) on different CPUs.

It is hopefully immediately clear that concurrency in that sense actually means sharing of resources, which is already due to the context switching very inefficient. And thus, that's not desirable for HPC. One should be carefully check the placement of processes and threads, therefore. It has a really strong performance impact.

### Scaling Laws and Limits of Parallelism
In short: If a serial program requires a time $T_1$ to complete, where a fraction, $0\le p\le1$, of that work can be parallized, and if we have $N$ workers then, to which we distribute the workload, the total runtime of the parallel program should be shorter by
```math
T_N = (1-p)T_1 + p\frac{T_1}{N} = \left(1 - \left(1-\frac{1}{N}\right)p\right) T_1 \le T_1\;.
```
We can re-express that in terms of speed-up: $S = T_1 / T_N$ (How much faster is the parallel execution with $N$ workers with respect to the serial execution?).
```math
S_N = \frac{1}{(1-p)+p/N}\;,
```
or, as a parallel efficiency $\varepsilon_N$ (in comparison to ideal scaling) by
```math
\varepsilon_N = \frac{T_1/N}{T_N}=\frac{1}{N(1-p)+p}\;.
```
This is [*Amdahl's Law*](https://en.wikipedia.org/wiki/Amdahl%27s_law). The essence is that with this simple model, we can make simple assessments about possible speed-up gains from simple scaling experiments - even if this model does not incorporate things like IO or communication (or, generally, parallelization) overhead. It is usually a good idea to have such a model in mind to gauge expectations about the code to be parallelized, to judge about performance issues, and to plan parallel HPC jobs (runtime estimation, CPU/GPU budget planning, etc.).

For the later experiments, $T_1$, $T_N$ and $N$ are to be measured/determined, from which $S_N$ and $\varepsilon_N$ can be calculated.


## Parallel Programming Models in Julia

We will look at the following programming models for parallelism, how they can be employed in Julia.

- simd / vectorization
- threads
- parallel workers and task-parallelism
- message passing

### SIMD (Vectorization)
For many purposes, LLVM does already loop auto-vectorization. For instance,
```julia
julia> A = rand(1000);

julia> B = rand(1000);

julia> @code_native C = A .+ B
...
.LBB0_61:                               # %vector.body
                                        # =>This Inner Loop Header: Depth=1
; │││││ @ simdloop.jl:77 within `macro expansion` @ broadcast.jl:995
; │││││┌ @ broadcast.jl:616 within `getindex`
; ││││││┌ @ broadcast.jl:620 within `_getindex`
; │││││││┌ @ broadcast.jl:671 within `_broadcast_getindex`
; ││││││││┌ @ broadcast.jl:695 within `_getindex`
; │││││││││┌ @ broadcast.jl:665 within `_broadcast_getindex`
; ││││││││││┌ @ essentials.jl:920 within `getindex`
	vmovupd	ymm0, ymmword ptr [rcx + 8*r8]
	vmovupd	ymm1, ymmword ptr [rcx + 8*r8 + 32]
	vmovupd	ymm2, ymmword ptr [rcx + 8*r8 + 64]
	vmovupd	ymm3, ymmword ptr [rcx + 8*r8 + 96]
; ││││││││└└└
; ││││││││ @ broadcast.jl:672 within `_broadcast_getindex`
; ││││││││┌ @ broadcast.jl:699 within `_broadcast_getindex_evalf`
; │││││││││┌ @ float.jl:495 within `+`
	vaddpd	ymm0, ymm0, ymmword ptr [rdx + 8*r8]
	vaddpd	ymm1, ymm1, ymmword ptr [rdx + 8*r8 + 32]
	vaddpd	ymm2, ymm2, ymmword ptr [rdx + 8*r8 + 64]
	vaddpd	ymm3, ymm3, ymmword ptr [rdx + 8*r8 + 96]
; │││││└└└└└
; │││││┌ @ array.jl:986 within `setindex!`
; ││││││┌ @ array.jl:991 within `_setindex!`
	vmovupd	ymmword ptr [rsi + 8*r8], ymm0
	vmovupd	ymmword ptr [rsi + 8*r8 + 32], ymm1
	vmovupd	ymmword ptr [rsi + 8*r8 + 64], ymm2
	vmovupd	ymmword ptr [rsi + 8*r8 + 96], ymm3
; │││││└└
; │││││ @ simdloop.jl:78 within `macro expansion`
; │││││┌ @ int.jl:87 within `+`
...
```
This example is of course not very useful here. The element-wise addition of two arrays is already memory-bandwidth bound. One doesn't gain here much through vectorization, as the CPU mostly waits for the data from the memory/caches. The compiler here vectorizes only to ymm-registers (AVX2) instead of zmm-registers (AVX512), as it "knows" that. And vectorization comprises also some overhead which is larger for wider vector-registers.

Conclusion: We can mostly rely on LLVM here to give us a good-compromize performance. If not, work gets harder to figure out why loops aren't vectorized, and to make the compiler to rethink its decision. There are macros like `@simd`, and packages like [`SIMD`](https://github.com/eschnett/SIMD.jl) and [`LoopVectorization`](https://github.com/JuliaSIMD/LoopVectorization.jl) (`@turbo`). But eventually, one needs to really look into the compiled code to see whether vectorization was done.

For instance,
```julia
julia> A = rand(1000);

julia> function simd_sum(A)
           s = 0.0
           @simd for i in eachindex(A)
               @inbounds s += A[i]
           end
           s
       end
simd_sum (generic function with 1 method)

julia> @code_native simd_sum(A)
...
.LBB0_6:                                # %vector.body
                                        # =>This Inner Loop Header: Depth=1
; ││ @ simdloop.jl:77 within `macro expansion` @ REPL[1]:4
; ││┌ @ float.jl:495 within `+`
	vaddpd	ymm1, ymm1, ymmword ptr [rcx + 8*rsi]
	vaddpd	ymm0, ymm0, ymmword ptr [rcx + 8*rsi + 32]
	vaddpd	ymm2, ymm2, ymmword ptr [rcx + 8*rsi + 64]
	vaddpd	ymm3, ymm3, ymmword ptr [rcx + 8*rsi + 96]
; ││└
; ││ @ simdloop.jl:78 within `macro expansion`
; ││┌ @ int.jl:87 within `+`
	add	rsi, 16
	cmp	rdx, rsi
	jne	.LBB0_6
# %bb.7:                                # %middle.block
; ││└
; ││ @ simdloop.jl:75 within `macro expansion`
	vaddpd	ymm0, ymm0, ymm1
	vaddpd	ymm0, ymm2, ymm0
	vaddpd	ymm0, ymm3, ymm0
	vextractf128	xmm1, ymm0, 1
	vaddpd	xmm0, xmm0, xmm1
	vshufpd	xmm1, xmm0, xmm0, 1             # xmm1 = xmm0[1,0]
	vaddsd	xmm0, xmm0, xmm1
	cmp	rax, rdx
	je	.LBB0_9
	.p2align	4, 0x90
...
```
Without `@simd`:
```julia
julia> function only_sum(A)
           s = 0.0
           for i in eachindex(A)
               s += A[i]
           end
           s
       end
only_sum (generic function with 1 method)

julia> @code_native only_sum(A)
...
.LBB0_6:                                # %L30
                                        # =>This Inner Loop Header: Depth=1
; │└
; │┌ @ float.jl:495 within `+`
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 8]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 16]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 24]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 32]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 40]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 48]
	vaddsd	xmm0, xmm0, qword ptr [rcx + 8*rdx + 56]
; │└
; │ @ REPL[5]:5 within `only_sum`
	add	rdx, 8
	cmp	rsi, rdx
	jne	.LBB0_6
# %bb.7:                                # %L46.loopexit.unr-lcssa.loopexit
	inc	rdx
	test	rax, rax
	je	.LBB0_11
...
So, sometimes it helps. (Note: This here was a reduction. Adding two array is quite a different thing.)

Using compact dot-notation very often helps, if applicable.


### Threads
[`Threads`](https://docs.julialang.org/en/v1/manual/multi-threading/) are in Julia already included into the `Base` package.

Using threading is rather simple.
```shell
> julia --threads 4 -e 'println(Threads.nthreads())'
4
> julia -t 4 -e 'Threads.@threads for i = 1:10 println(Threads.threadid()) end'
3
5
5
2
2
2
3
4
4
4
```
**So, usage is simple! Only go sure that there are no loop-carried dependencies!!**

Instead of `--threads`, also `-t` can be used. Thread IDs don't start with 1 (kept for the main julia process)!

Thread-to-CPU placement and pinning. For HPC (performance), it is essential to fix the threads on certain CPUs, and especially not to let several threads run on the same CPU. The `ThreadPinning` package can help here.
```shell
> julia -t 4 -e 'using ThreadPinning; threadinfo()'
```
shows how threads are placed randomly. Possibly also on top of each other.

You can use an environment variable `JULIA_EXCLUSIVE=1 julia --threads 4 ...` to pin and place the threads uniquely (as far as possible). From the `ThreadPinning` package, you can even have a finer control via `pinthreads(:cores)`, where you specify a list of CPU IDs, and whether to pin to cores or to sockets. One even can (re-)use a threadpool. (Checkout `??pinthreads`.)

### Task-Parallelism (distributed, pmap)

### MPI (Message Passing Interface)


## Hands-on

- Ray-Tracing / Path-Tracing (Visualization)
- PDE Solution (?)
