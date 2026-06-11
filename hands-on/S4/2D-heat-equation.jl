using BenchmarkTools, Test
using KernelAbstractions


# ----------------------------------------------------------------------------------------
# AGNOSTIC KERNEL TO BE IMPLEMENTED
# ----------------------------------------------------------------------------------------

@kernel function heat_step_kernel!(T2, @Const(T1), alpha)
    # TODO 1: Retrieve the 2D (!) global index of the current thread
    # Hint: look at the Julia help mode for @index...

    # TODO 2: Extract the dimensions of the grid (Nx, Ny)

    # TODO 3: Implement boundary checks.
    # Hint: the stencil requires neighbors, so do not compute on the outer edges (where i=1, i=Nx, j=1, j=Ny)

    # TODO 4: Apply the 5-point stencil equation and write to T2.
    # Hint: use @inbounds to avoid performance penalties...
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

# TODO 5: Load your GPU backend (CUDA, AMDGPU, Metal, oneAPI); add suited "using ..." on top
# TODO 6: Move arrays to the GPU device
# TODO 7: Run run_heat_step! on the device arrays
# TODO 8: Pull the result back to the host and compare with T_new_ref

