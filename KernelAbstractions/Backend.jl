using Adapt
using KernelAbstractions
const KA = KernelAbstractions

if @isdefined(FORCE_CPU_BACKEND) && FORCE_CPU_BACKEND in (1, "true", true)
    onlycpu = true
elseif !@isdefined(FORCE_CPU_BACKEND) || FORCE_CPU_BACKEND in (0, "false", false)
    onlycpu = false
else
    throw(AssertionError("FORCE_CPU_BACKEND=$FORCE_CPU_BACKEND not valid; must be one of: 1, true, 'true' or 0, false, 'false'"))
end

if Base.find_package("oneAPI") !== nothing && onlycpu == false
    using oneAPI
    #using oneAPI.oneAPIKernels
    const backend = oneAPI.oneAPIBackend()
    const DevArray = oneAPI.oneArray
    const DevFloat = Float64
    const DevLibrary = oneAPI
    println("Using oneAPI.jl")

elseif Base.find_package("CUDA") !== nothing && onlycpu == false
    using CUDA
    #using CUDA.CUDAKernels
    const backend = CUDA.CUDABackend()
    const DevArray = CuArray
    const DevFloat = Float32
    const DevLibrary = CUDA
    CUDA.allowscalar(false)
    println("Using CUDA.jl")

elseif Base.find_package("AMDGPU") !== nothing && onlycpu == false
    using AMDGPU
    #using AMDGPU.ROCKernels
    const backend = AMDGPU.ROCBackend()
    const DevArray = ROCArray
    const DevFloat = Float32
    const DevLibrary = AMDGPU
    println("Using AMDGPU.jl")

elseif Base.find_package("Metal") !== nothing && onlycpu == false
    using Metal
    #using Metal.MetalKernels
    const backend = Metal.MetalBackend()
    const DevArray = Metal.MtlArray
    const DevFloat = Float32
    const DevLibrary = Metal
    println("Using Metal.jl")
    
else
    using ThreadPinning
    const backend = KA.CPU()
    const DevArray = Array
    const DevFloat = Float64
    println("Using CPU and ThreadPinning.jl")
    println("""
        REMEMBER: no DevLibrary defined!
        We recommend you to use in the code, when needed:
            IDDL = @isdefined DevLibrary        # "is defined DevLibrary?"
            IDDL && DevLibrary.synchronize()    # example of usage
    """)
    pinthreads(:cores)
    #threadinfo()
end
