# TO RUN THIS FILE, open a julia shell and run the following:
# - for a pure-CPU vs KernelAbstractions-CPU comparison:
#      FORCE_CPU_BACKEND=true; include("2D-heat-equation_benchmarking.jl")      # first run
# - for a CPU vs GPU:
#      FORCE_CPU_BACKEND=false; include("2D-heat-equation_benchmarking.jl")     # first run
#
# Once included for the first time, you can run differen banchmarks (with same backend):
#       T_init = zeros(Float32,256,256);
#       T_init[128,128] = 1.0f0;
#       main_benchmark(T_init; N=128, alpha=0.2f0, steps=100, workgroupsize=(16,16))

using BenchmarkTools

# Backend.jl reads the var FORCE_CPU_BACKEND
#     - if not set (or if set to 0, false, or 'false'), uses the first available GPU backend it finds, i.e:
#         oneAPI, NVidia, AMDCPU, Metal
#     - if set to 1, true, or 'true', uses the KernelAbstractions.CPU() backend
include("../../KernelAbstractions/Backend.jl")

@kernel function heat_step_kernel!(T2, @Const(T1), alpha)
    i, j = @index(Global, NTuple)
    Nx, Ny = size(T1)

    if i > 1 && i < Nx && j > 1 && j < Ny
        @inbounds T2[i, j] = T1[i, j] + alpha * (T1[i+1, j] + T1[i-1, j] + T1[i, j+1] + T1[i, j-1] - 4 * T1[i, j])
    end
end

function evolve_heat!(T1, T2, alpha, n_steps; workgroupsize=(16, 16))
    backend = get_backend(T1)
    kernel! = heat_step_kernel!(backend, workgroupsize)
    ndrange = size(T1)

    active, buffer = T1, T2
    for _ in 1:n_steps
        kernel!(buffer, active, alpha, ndrange=ndrange)
        KernelAbstractions.synchronize(backend)
        active, buffer = buffer, active
    end
    return active
end

function main_benchmark(T1=nothing; N=2048, alpha=0.2f0, steps=100, workgroupsize=(16,16))
    # NOTE: you can further increase the linear grid size N to saturate the GPU

    T_host = isnothing(T1) ? rand(Float32, N, N) : T1

    T1 = DevArray(T_host)
    T2 = DevArray(T_host)

    # Warmup to force JIT compilation
    evolve_heat!(T1, T2, alpha, 1; workgroupsize=workgroupsize)

    println("Benchmarking $steps steps on $(DevArray) grid size $(N)x$(N):")

    # Evaluate performance. Allocations must read 0.
    res = @benchmark evolve_heat!($T1, $T2, $alpha, $steps)

    return res
end

main_benchmark()

