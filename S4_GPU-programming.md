# GPU programming


- [GPU programming](#gpu-programming)
  - [Using a GPU backend](#using-a-gpu-backend)
  - [GPU info and memory management](#gpu-info-and-memory-management)
  - [Working with GPU arrays](#working-with-gpu-arrays)
  - [Kernels, i.e. where broadcasting breaks down](#kernels-ie-where-broadcasting-breaks-down)
  - [KernelAbstractions.jl](#kernelabstractionsjl)
    - [REPL intro to KernelAbstractions.jl](#repl-intro-to-kernelabstractionsjl)
    - [Basic KA example](#basic-ka-example)
    - [A more complicated KA example](#a-more-complicated-ka-example)


<br>
<br>
<br>



## Using a GPU backend

```julia
using LinearAlgebra, BenchmarkTools, Test

# Customizite this part depending on your GPU backend

# E.g. Apple Silicon integrated GPU
using Metal
const backend = Metal.MetalBackend()
const DevLibrary = Metal            
const DevArray = Metal.MtlArray
const DevFloat = Float32

# E.g. Nvidia GPU
using CUDA
const backend = CUDA.CUDABackend()
const DevLibrary = CUDA            
const DevArray = CUDA.CuArray
const DevFloat = Float64
```

NOTE: **some functions are not present in all backends!**
We will prepend `CUDA.` (instead of `DevLibrary.`) the Nvidia-specific ones.

NOTE: as always in Julia, FIRST FUNCTION CALL TAKES A LOT OF TIME, due to Julia method compilation

<br>
<br>



## GPU info and memory management

```julia
# general info 
DevLibrary.versioninfo()                # driver + toolkit version + device overview
DevLibrary.devices()                    # list all GPUs available
DevLibrary.device!(2)                   # select to work with this specific GPU (only if you have more than one!)
dev = DevLibrary.device()               # current GPU device selected
InteractiveUtils.methodswith(typeof(dev),DevLibrary)        # which methods are available for this device?

# CUDA specifics
CUDA.functional()                       # if this works, you're good to go!
CUDA.name(dev)                          # e.g. "Tesla V100-PCIE-16GB"
CUDA.capability(dev)                    # compute capability, e.g. v"7.0.0"

CUDA.total_memory() / 1024^3            # total device VRAM (in bytes)
CUDA.free_memory() / 1024^3             # free device VRAM (in bytes)
CUDA.cached_memory() / 1024^3            # cached device VRAM (in bytes): available but previosly used
CUDA.used_memory() / 1024^3             # used device VRAM (in bytes)

# Behind the scenes, a memory pool will hold on to your objects and cache the underlying memory to speed up future allocations
CUDA.pool_status()                      # memory status of the current GPU and the active memory pool
CUDA.reclaim()                          # free GPU memory before calling into functionality that does not use the CUDA memory pool
```

<br>

Example of memory management in CUDA:

```julia
CUDA.pool_status()                  # initial state
    # Effective GPU memory usage: 1.92% (309.938 MiB/15.766 GiB)
    # Memory pool usage: 0 bytes (0 bytes reserved)
a = CuArray{Int}(undef, 1024); CUDA.pool_status()     # allocate 8KB
    # Effective GPU memory usage: 2.12% (341.938 MiB/15.766 GiB)
    # Memory pool usage: 8.000 KiB (32.000 MiB reserved)        # 32MB are preallocated by the GPU as buffer
a = nothing; GC.gc(true); CUDA.pool_status()
    # Effective GPU memory usage: 2.12% (341.938 MiB/15.766 GiB)
    # Memory pool usage: 0 bytes (32.000 MiB reserved)    
CUDA.reclaim()          # if for some reason you need all cached memory to be reclaimed
CUDA.pool_status()
    # Effective GPU memory usage: 1.92% (309.938 MiB/15.766 GiB)
    # Memory pool usage: 0 bytes (0 bytes reserved)
# GPU memory is scarce + GC is less predictable than CPU => sometimes you need manual intervention

# regarding the pre-allocation that CUDA does:
a = CUDA.zeros(Int64, 4*1024*1024); CUDA.pool_status()
    # Effective GPU memory usage: 2.12% (341.938 MiB/15.766 GiB)
    # Memory pool usage: 32.000 MiB (32.000 MiB reserved)
a = nothing; GC.gc(); CUDA.reclaim(); CUDA.pool_status()
    # Effective GPU memory usage: 1.92% (309.938 MiB/15.766 GiB)
    # Memory pool usage: 0 bytes (0 bytes reserved)
a = CUDA.zeros(Int64,1+ 4*1024*1024); CUDA.pool_status()
    # Effective GPU memory usage: 2.32% (373.938 MiB/15.766 GiB)
    # Memory pool usage: 32.000 MiB (64.000 MiB reserved)       # now is 64!

# NOTE: cuarrays are managed by Julia garbage collector
# => they will be collected once they are unreachable, and their memory will be freed
# => no need for manual memory management, just make sure your objects are not reachable (i.e., there are no instances or references)

# To avoid having to depend on the Julia GC to free up memory, 
# you can directly inform CUDA.jl when an allocation can be freed (or reused) with unsafe_free!
a = CuArray([1])        # 1-element CuArray{Int64,1,Nothing}:
CUDA.unsafe_free!(a)
a                       # ERROR: ArgumentError: Attempt to use a freed reference
```

<br>
<br>




## Working with GPU arrays


```julia
# ------------------------------------------------------------
# DevArrays and data transfer CPU <-> GPU
# ------------------------------------------------------------

# Creating a CuArray will allocate data on the GPU, copying elements to it will upload, 
# and converting back to an Array will download values to the CPU:

v = rand(Float32, 1024);    # plain Julia Vector on CPU
v_d = DevArray(v);          # upload to GPU (allocates device memory)
v2 = Array(v_d);            # download back to CPU

# Better approach: allocate directly on the GPU, when possible, using suited functions
# => no data transfer, better performance
DevArray.rand(Float32, 5)           # 5-element CuArray{Float32, 1, CUDACore.DeviceMemory}:
DevArray.zeros(Int32, 1024)         # 1024-element CuArray{Int32, 1, CUDACore.DeviceMemory}
DevArray.ones(Int64, 1024)          # 1024-element CuArray{Int64, 1, CUDACore.DeviceMemory}
DevArray.fill(1.0, 10,3)            # 10×3 CuArray{Float64, 2, CUDACore.DeviceMemory}:
DevArray{Float32}(undef, 1024)      # 1024-element CuArray{Float32, 1, CUDACore.DeviceMemory}:


# ------------------------------------------------------------
# BROADCASTING — element-wise ops, no kernel needed
# ------------------------------------------------------------

# allocate + fill directly on GPU
x_d = DevLibrary.fill(1.0f0, 1024);     # FIRST FUNCTION CALL TAKES A LOT OF TIME, due to Julia compilation
y_d = DevLibrary.fill(2.0f0, 1024);
y_d .+= x_d;                            # launches (and JUST LAUNCHES!!!) a GPU kernel automatically!

DevLibrary.synchronize()
# IMPORTANT: the CPU can assign jobs to the GPU and then go do other stuff while the GPU completes its tasks.
# => AN IMMEDIATE @test all(y_d .== 3.0f0) MIGHT FAIL!
# => DevLibrary.synchronize() will make the CPU stop until the queued GPU tasks are done
#    (similar to how Base.@sync waits for distributed CPU tasks)
# Without such synchronization, YOU'D BE MEASURING THE TIME TAKES TO LAUNCH THE COMPUTATION, NOT THE TIME TO PERFORM IT!
#
# NOTE:  most of the time you don't need to synchronize explicitly;
# many operations, like copying memory from the GPU to the CPU, implicitly synchronize execution.
#
# NOTE: synchronize() is also called @sync in some libraries, e.g. CUDA
@test all(y_d .== 3.0f0)

z_d = @. x_d * 2 + sin(y_d)         # fused broadcast, still one kernel
supertypes(typeof(z_d))             # (MtlVector{...}, GPUArraysCore.AbstractGPUVector{Float32}, DenseVector{Float32}, AbstractVector{Float32}, Any)
#
# Key point: DevArray <: AbstractArray
# => it behaves like any Julia array 
# => the dot-fusion mechanism (lowered to Base.broadcast) works identically on CPU and GPU!



# ------------------------------------------------------------
# various flavours of (map)reduce(dim)
# ------------------------------------------------------------

a = DevLibrary.rand(5,4)

# map : apply f to each element => return a new collection (same length)
map(sin,a)
# reduce: fold a binary operator over a collection => return a single value
#     left-associative, e.g. on CPU: reduce(-, [1,2,3,4])               # ((1-2)-3)-4 = -8
reduce(+, a)
# mapreduce: apply f to each element, then reduce with op => return single value
#     more efficient than map(...) |> reduce(...) — avoids the intermediate array.
mapreduce(x -> x^2, +, a) 

# What about reduce(-, a) on the GPU?
reduce(-, a)        # ERROR: GPUArrays.jl needs to know the neutral element for your operator! Please pass it as an explicit argument to GPUArrays.mapreducedim!
# CPU reduce is sequential:  reduce(-, [1,2,3,4])) becomes (((a-b)-c)-d) => it needs no identity
# GPU reduction is a parallel alg: threads reduce independent subsets simultaneously, then merge
# => seach thread must initialize its accumulator with a neutral element (identity of the operator)
#      For +, *, max and min the init argument is optional: + -> 0, * -> 1, max -> -Inf, min -> Inf - has no identity (0 - x ≠ x), and it's not associative, so the GPU can't parallelize it safely.

# NOTE: regarding reduce with non-associative operators
a = DevLibrary.ones(3);
b = Array(a);
reduce(-, b)                    # -1.0f0 : CPU left fold: (1 - 1) - 1 = -1     # deterministic, sequential
reduce(-,b; init=0.0f0)         # -3.0f0 : CPU left fold with init prepended to sequence: ((0 - 1) - 1) - 1 = -3    # still
reduce(-, a; init=0)            # 1.0f0  : GPU init is not prepended, it's the per-thread accumulator seed!
# thread 1,2,3: 0 - 1 = -1   =>  merge: (-1)-(-1)-(-1) = 1
# => GPU result depends entirely on how the GPU happens to schedule and merge the partial results
# => with a different array size or thread count you'd get yet another answer.
#
# Key point: reduce is only predictable when the operator is associative (and ideally commutative), like + or *
# - is not associative, so the result depends on the order of evaluation



# ------------------------------------------------------------
# Linear Algebra : transparent CUBLAS/cuSOLVER dispatch
# ------------------------------------------------------------

A = DevLibrary.rand(Float32, 1024, 1024);
B = DevLibrary.rand(Float32, 1024, 1024);
C = A * B                           # dispatches to e.g. CUBLAS dgemm automatically
@test all(C .≈ A*B)

# No code change needed wrt CPU, Julia's multiple dispatch selects the GPU BLAS backend based on array type



# ------------------------------------------------------------
# Allowscalar
# ------------------------------------------------------------

# Many array operations in Julia are implemented using loops, processing one element at a time
# Doing so with GPU arrays is very ineffective: the loop won't actually execute on the GPU, 
# but transfer one element at a time and process it on the CPU
#
# NOTE: with CUDA, scalar indexing is only allowed in an interactive session, e.g. the REPL, 
# because it is convenient when porting CPU code to the GPU
# You can change this behaviour with CUDA.allowscalar(false)
CUDA.allowscalar(false)
x = DevLibrary.rand(Float32, 2^16);
s = 0;
for i in eachindex(x)
    s += x[i]
end
# ERROR: Scalar indexing is disallowed

# In a non-interactive session (e.g. when running code from a script or application) 
# scalar indexing is disallowed by default even in CUDA.
# There is no global toggle to allow scalar indexing; if you really need it, 
# you can mark expressions using allowscalar with do-block syntax or @allowscalar macro:
CUDA.allowscalar() do
    x[1] += 1
end
CUDA.@allowscalar a[1] += 1

# Solution: use native functions!
s = sum(x)                          # GPU reduction, result is a 0-d DevArray



# ------------------------------------------------------------
# Benchmarking : always sync before timing
# ------------------------------------------------------------

x_gpu = DevLibrary.rand(2^16);

# WRONG : GPU calls are async, this times only kernel launch!
@time sum(x_gpu .*2)

# CORRECT : forces completion before stopping the clock
DevLibrary.@sync @time sum(x_gpu .* 2)

# or, with BenchmarkTools:
@btime DevLibrary.@sync sum($x_gpu .*2 )
@btime sum($Array(x_gpu) .*2 )
# speedup: GPU wins with large N (i.e. when code is compute-bound)
```

<br>
<br>





## Kernels, i.e. where broadcasting breaks down


Broadcasting works when ops are element-wise or well-known reductions.
It fails (or is inefficient) when you need:
- shared memory between threads
- custom reduction trees
- stencil access patterns (e.g. neighbours in a grid)
- fused multi-pass algorithms

101 about kernels:
* kernels are written as ordinary Julia functions, returning nothing
* to launch kernels, use the suited macro: @cuda, @metal, @oneapi, @amdgpu
* this automatically (re)compiles the my_kernel function and launches it on the current GPU (selected by calling device!).

Regarding terminology:

* <https://people.eecs.ku.edu/~jrmiller/Courses/675/InClass/GPU/GPUTerminology.html>
* <https://modal.com/gpu-glossary/device-hardware>
* <https://amdgpu.juliagpu.org/stable/tutorials/quickstart#Naming-conventions>

| Concept                       | CUDA                  | AMDGPU                    | Metal                                     | oneAPI                    |
|-------------------------------|-----------------------|---------------------------|-------------------------------------------|---------------------------|
| array type                    | `CuArray`             | `ROCArray`                | `MtlArray`                                | `oneArray`                |
| Launch macro                  | `@cuda`               | `@roc`                    | `@metal`                                  | `@oneapi`                 |
| Threads param                 | `threads=`            | `groupsize=`              | `threads=`                                | `items=`                  |
| Blocks param                  | `blocks=`             | `gridsize=`               | `groups=  `                               | `groups=`                 |
| Thread index                  | `threadIdx().x`       | `workitemIdx().x`         | `thread_position_in_threadgroup().x`      | `get_group_id(dim=0)`     |
| Block index                   | `blockIdx().x`        | `workgroupIdx().x`        | `threadgroup_position_in_grid().x`        | `get_local_id(dim=0)`     |
| Block dimension               | `blockDim()`          | `workgroupDim()`          | —                                         |  -                        |
| Grid dimension                | `gridDim()`           | `gridgroupDim()`          | —                                         | `get_global_id(dim=0)`    |
| Flat index                    | formula*              | formula**                 | `thread_position_in_grid().x`             | `get_global_id()`         |
| Host sync                     | `synchronize()`       | `synchronize()`           | `synchronize()`                           | `synchronize()`           |
| Kernel barrier/sync           | `sync_threads()`      | `sync_workgroup()`        | `threadgroup_barrier()`                   | `barrier()`               |
| Free memory                   | `available_memory()`  | `available_memory()`      | -                                         | —                         |
| Explicit device-memory free   | `unsafe_free!(A)`     | `unsafe_free!(A)`         | `unsafe_free!(A)`                         | `unsafe_free!(A)`         |

\* = `(blockIdx().x - 1) * blockDim().x + threadIdx().x`
** = `(workgroupIdx().x - 1) * workgroupDim().x + workitemIdx().x`

<br>

Typical approach for a GPU application:

1. develop an application **using generic array functionality**, and test it on the CPU with the Array type
2. port your application to the GPU by switching to the `DevArray` type
3. disallow the CPU fallback ("scalar indexing") to find operations that are not implemented for or incompatible with GPU execution
4. (optional) use lower-level, DevLibrary-specific interfaces to implement missing functionality or optimize performance


```julia
using CUDA, Test

function my_kernel!(z, x, y, a)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    # NOTE: blockIdx, blockDim, threadIdx are 1-based in Julia (unlike C++)!
    if i <= length(y)          # guard: last block may have excess threads
        z[i] = a * x[i] + y[i]
    end
    return                     # kernels MUST return nothing
end

N  = 2^20
a  = 2.5f0
x, y = CUDA.rand(Float32, N), CUDA.rand(Float32, N)
z = CUDA.CuArray{Float32}(undef, N)

threads = 256               # threads per block, typically 128/256/512
blocks = cld(N, threads)    # cld = ceiling division, ensures full coverage

# NOTE: simply using @cuda only launches a single thread => use the threads and blocks keyword arguments!
@cuda threads=threads blocks=blocks my_kernel!(z, x, y, a)
CUDA.synchronize()

# verify against CPU
x_cpu, y_cpu, z_cpu = Array(x), Array(y), Array(z)   # download after kernel
@test all(@. isapprox(z, a * x + y))
```

NOTE: we are not allowed to have runtime dispatches, all function calls need to be determined at compile time!
<br>

Big issue: codes like that are not portable due to terminology differences!
=> **SOLUTION: KernelAbstractions.jl**

<br>
<br>





## KernelAbstractions.jl


<br>
<br>


### REPL intro to KernelAbstractions.jl

Before writing kernels, `KernelAbstractions` provides backend-agnostic helpers
for allocation and data transfer — no kernel required:

```julia
using KernelAbstractions
const KA = KernelAbstractions
using CUDA
const backend = CUDA.CUDABackend()

# NOTE: KA brings also the CPU() backend!
KA.allocate(CPU(), Float32, 8)          # perfect to test stuff

# --- allocation ---
a = KA.allocate(backend, Float32, 8)    # uninitialized device array (like undef)
b = KA.zeros(backend, Float32, 8)       # zero-filled device array
c = KA.ones(backend, Float32, (4, 4))   # ones, works with tuple shapes too


# --- transfer CPU -> device and back ---
# RAND NOT IMPLEMENTED! => we can use the CPU one and copy to GPU
cpu = rand(Float32, 8)
d = KA.allocate(backend, Float32, 8)
copyto!(d, cpu)                 # in-place copy; device array must already exist
# one-liner alternative: allocate + copy in one shot
copyto!(KA.allocate(backend, Float32, 8), rand(Float32, 8))
# OR, use the device library explicitly
CUDA.rand(Float32, 8)            # HERE THERE IS NOT DATA TRANSFER (but is not pure KA.jl)
# to transfer back from device to host
b_cpu = Array(b)                 # always works regardless of backend


# --- inspect: KA can query the backend of any array ---
KA.get_backend(b)        # CUDABackend() — works for CuArray, ROCArray, MtlArray, etc.

# --- synchronize (flush all pending kernel/copy ops) ---
KA.synchronize(backend)
```

> `KA.allocate`, `KA.zeros`, `KA.ones` mirror `CUDA.CuArray(undef,...)`, `CUDA.zeros`, `CUDA.ones`
> but are **backend-agnostic**: swap `backend` and the rest of the code stays identical!

<br>
<br>
<br>




### Basic KA example


**IMPORTANT**: to be manually chosen:

* WorkGroup (Thread Block) size, i.e. #threads in each TB; must be a power of 2, recommended `32` (or 64)
* DRange (Grid) size, i.e. total #threads to be spawned; set to your problem size (e.g. vector length)

<br>


```julia
using Test, KernelAbstractions
using CUDA
const backend = CUDA.CUDABackend()
const DevLibrary = CUDA            
const DevArray = CUDA.CuArray
const DevFloat = Float64

@kernel function my_kernel!(z, @Const(x), @Const(y), a)
    # @Const: tell the compiler x, y are read-only -> enables caching optimisations
    i = @index(Global)      # global thread index across all groups (≈ CUDA flat index)
    z[i] = a * x[i] + y[i]
    # return statement not permitted in a kernel function
end

N = 2^20
a = 2.5f0
x, y = DevLibrary.rand(Float32, N), DevLibrary.rand(Float32, N)
z = DevArray{Float32}(undef, N)

# STEP 1: compile the kernel for the chosen backend (here CUDA)
kernel = my_kernel!(backend, 32)    # 32 = WorkGroup (Thread Block) size; use 32 or 64
# STEP 2: run the kernel
kernel(z, x, y, a; ndrange = N)     # NDRange (Grid) size, i.e. total #threads; set to vector size
DevLibrary.synchronize()

# verify against CPU
x_cpu, y_cpu, z_cpu = Array(x), Array(y), Array(z)   # download after kernel
@test all(@. isapprox(z, a * x + y))
```


Equivalent kernel, without using any `DevLibrary`, `DevArray`, etc:


```julia
using Test, KernelAbstractions
const KA = KernelAbstractions
using CUDA
const backend = CUDA.CUDABackend()

@kernel function my_kernel!(z, @Const(x), @Const(y), a)
    i = @index(Global)
    z[i] = a * x[i] + y[i]
end

N = 2^20
a = 2.5f0
x = copyto!(KA.allocate(backend, Float32, N), rand(Float32, N))
y = copyto!(KA.allocate(backend, Float32, N), rand(Float32, N))
z = KA.zeros(backend, Float32, N)

kernel = my_kernel!(backend, 32)    # 32 = WorkGroup (Thread Block) size; use 32 or 64
kernel(z, x, y, a; ndrange = N)     # NDRange (Grid) size, i.e. total #threads; set to vector size
KA.synchronize(backend)

# verify against CPU
x_cpu, y_cpu, z_cpu = Array(x), Array(y), Array(z)   # download after kernel
@test all(@. isapprox(z, a * x + y))
```

<br>

Regarding the name equivalence between KernelAbstractions.jl and CUDA:


| KernelAbstractions.jl                           | CUDA.jl                                             | CUDA C++                                |
| ----------------------------------------------- | --------------------------------------------------- | :-------------------------------------- |
| `@kernel`                                       | `function` + `@cuda`                                | `__global__`                            |
| `@index(Global)`                                | `(blockIdx().x - 1) * blockDim().x + threadIdx().x` | `blockIdx.x * blockDim.x + threadIdx.x` |
| `@index(Local)`                                 | `threadIdx().x`                                     | `threadIdx.x`                           |
| `@index(Group)`                                 | `blockIdx().x`                                      | `blockIdx.x`                            |
| `@localmem T (N,)`                              | —                                                   | `__shared__ T shmem[N]`                 |
| `@synchronize()`                                | `sync_threads()`                                    | `__syncthreads()`                       |
| `@groupsize()[1]`                               | `blockDim().x`                                      | `blockDim.x`                            |
| `@Const(x)`                                     | —                                                   | `const T* __restrict__ x`               |
| `kernel(Backend(), groupsize)(args; ndrange=N)` | `@cuda threads=T blocks=B f(args)`                  | `f<<<B, T>>>(args)`                     |

Note: in CUDA C++ `threadIdx`, `blockIdx`, `blockDim` are **built-in structs** (no parentheses), 
while in CUDA.jl they are **functions** returning a struct — hence `threadIdx().x` with `()`.

<br>
<br>




### A more complicated KA example

```julia
using Test, KernelAbstractions
using CUDA
const backend = CUDA.CUDABackend()
const DevLibrary = CUDA
const DevArray = CUDA.CuArray
const DevFloat = Float32

@kernel function block_sum_kernel!(out, @Const(x))

    gi = @index(Global)  # global thread index across all groups (≈ CUDA flat index)
    li = @index(Local)   # thread index within this group (1-based, ≈ threadIdx)
    bi = @index(Group)   # group index (≈ blockIdx)

    # @localmem: allocates shared/local memory (fast, on-chip, per-group)
    # size must be known at compile time -> tied to groupsize chosen at launch
    shmem = @localmem DevFloat (@groupsize()[1],)

    # PHASE 1: each thread loads one element from slow global memory into fast shmem
    # out-of-bounds threads load 0 (neutral element for +) to avoid if-branching later
    shmem[li] = gi <= length(x) ? x[gi] : 0f0

    @synchronize()  # barrier: no thread proceeds until ALL threads finished loading

    # PHASE 2: parallel tree reduction within the group
    # each step halves the active threads; stride walks down powers of 2
    # e.g. groupsize=8: steps are 4,2,1
    #   step 4: threads 1..4 add shmem[1..4] += shmem[5..8]
    #   step 2: threads 1..2 add shmem[1..2] += shmem[3..4]
    #   step 1: thread  1    adds shmem[1]   += shmem[2]
    stride = @groupsize()[1] >> 1   # >> 1 == ÷ 2, but avoids integer division
    while stride > 0
        if li <= stride
            shmem[li] += shmem[li + stride]
        end
        @synchronize()   # wait after each step — threads in later steps
                         # read values written by threads in this step
        stride >>= 1
    end

    # PHASE 3: thread 1 of each group writes the group's partial sum to global memory
    if li == 1
        out[bi] = shmem[1]   # one output element per group
    end
end

N = 2^20
x = DevLibrary.rand(Float32, N)
groupsize = 256                 # threads per group — must be power of 2
ngroups = cld(N, groupsize)     # ceiling division: number of groups

out = DevArray{Float32}(undef, ngroups)      # partial sums buffer: one element per group

kernel = block_sum_kernel!(backend, groupsize)
kernel(out, x; ndrange = N)
DevLibrary.synchronize()

# each group produced one partial sum -> final reduction on CPU (ngroups is small)
total = sum(Array(out))

@test isapprox(total, sum(Array(x)), rtol=1e-4)
```

<br>
<br>
