# TO RUN THIS FILE, open a julia shell and run:
# - on CPU and on GPUs that supports Float64:
#      include("<filename>.jl")
# - on GPUs that only support Float32:
#      using ChangePrecision                        # install this package if you don't have it
#      @changeprecision Float32 include("<filename>.jl")
#
# ACTUALLY, here the values are only Float32, so you can do for the Float32-only GPUs the same as for the others
#

include("./Backend.jl")

struct MyStruct
    a::Float32
    b::Vector{Float32}
end

struct DevMyStruct{T1,T2}
    a::T1
    b::T2
end

# THIS IS MANDATORY!
function Adapt.adapt_structure(to, s::DevMyStruct)
    DevMyStruct(adapt(to, s.a), adapt(to, s.b))
end

function Adapt.adapt_structure(to, s::MyStruct)
    DevMyStruct(adapt(to, s.a), adapt(to, s.b))
end

MS = MyStruct(1f0, [2f0, 3f0])
DevMS = DevMyStruct(MS.a, MS.b)

MS_dev = adapt(backend, MS)         # works!
#MS_dev = adapt(backend, DevMS)     # also this works

@kernel function my_kernel(vec, s)
    I = @index(Global)
    vec[I] = 2 * vec[I] + s.b[1]
end


A = KA.ones(backend, DevFloat, 8, 8)
my_kernel(backend, 64)(A, MS_dev, ndrange=size(A))
KA.synchronize(backend)

A_cpu = Array(A)
test = all(A_cpu .≈ 4f0)
println("Test: ", test ? "Passed" : "Failed")
if test == false
    display(A_cpu)
end
