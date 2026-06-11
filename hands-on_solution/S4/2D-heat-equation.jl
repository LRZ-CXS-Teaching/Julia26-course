using BenchmarkTools, Test
using KernelAbstractions
using Metal
const backend = Metal.MetalBackend()
const DevArray = Metal.MtlArray
const DevFloat = Float32
const DevLibrary = Metal


# ----------------------------------------------------------------------------------------
# AGNOSTIC KERNEL TO BE IMPLEMENTED
# ----------------------------------------------------------------------------------------

@kernel function heat_step_kernel!(T2, @Const(T1), alpha)
    i, j = @index(Global, NTuple)
    Nx, Ny = size(T1)

    # Skip the outer boundary
    if 2 <= i <= Nx - 1 && 2 <= j <= Ny - 1
        @inbounds T2[i, j] = T1[i, j] + alpha * (
            T1[i+1, j] + T1[i-1, j] + T1[i, j+1] + T1[i, j-1] - 4 * T1[i, j]
        )
    end

end


# ----------------------------------------------------------------------------------------
# NOT-TO-BE-EDITED SECTION
# ----------------------------------------------------------------------------------------

# Wrapper of the GPU kernel for execution
function run_heat_step!(T2, T1, alpha; ndrange=size(T1), workgroupsize=(16, 16))
    backend = get_backend(T1)                               # extract the backend dynamically
    kernel! = heat_step_kernel!(backend, workgroupsize)     # instantiate the kernel
    kernel!(T2, T1, alpha, ndrange=ndrange)                 # launch the kernel
    KernelAbstractions.synchronize(backend)                 # ensure the device has finished execution before returning
end

function cpu_reference_step!(T2, T1, alpha)
    Nx, Ny = size(T1)
    for j in 2:(Ny-1), i in 2:(Nx-1)
        @inbounds T2[i, j] = T1[i, j] + alpha * (T1[i+1, j] + T1[i-1, j] + T1[i, j+1] + T1[i, j-1] - 4 * T1[i, j])
    end
end

# ---------- Validation ----------

N = 1024
alpha = 0.1f0

# Initialize CPU arrays
T1 = rand(Float32, N, N)
T2 = copy(T1)
T2_ref = copy(T1)

# Run cpu and KernelAbstractions kernel
cpu_reference_step!(T2_ref, T1, alpha)
run_heat_step!(T2, T1, alpha)

# Check correctness
@test all(isapprox(T2, T2_ref))
println("CPU kernel matches reference: ", isapprox(T2, T2_ref))



# ----------------------------------------------------------------------------------------
# USE A PROPER GPU BACKEND
# ----------------------------------------------------------------------------------------

T1_d = DevArray(T1)
T2_d = copy(T1_d)

run_heat_step!(T2_d, T1_d, alpha)

# we need to copy the GPU array back to the CPu to make the tests
T2_gpu = Array(T2_d)
@test all(isapprox(T2_gpu, T2_ref; rtol=1f-6, atol=1f-6))
println("GPU kernel matches reference: ", isapprox(T2_gpu, T2_ref; rtol=1f-6, atol=1f-6))
