# TO RUN THIS FILE, open a julia shell and run:
# - on CPU and on GPUs that supports Float64:
#      include("<filename>.jl")
# - on GPUs that only support Float32:
#      using ChangePrecision                        # install this package if you don't have it
#      @changeprecision Float32 include("<filename>.jl")
#

include("./Backend.jl")


struct MyStruct{A,B}
    a::A
    b::B
end

Adapt.@adapt_structure MyStruct
MS = MyStruct(1.0f0, DevArray([2.0f0, 3.0f0]))

println("  isbits(MS) = $(isbits(MS)  ) \t typeof(MS)   =  $(typeof(MS))")
println("isbits(MS.a) = $(isbits(MS.a)) \t typeof(MS.a) =  $(typeof(MS.a))")
println("isbits(MS.b) = $(isbits(MS.b)) \t typeof(MS.b) =  $(typeof(MS.b))")


@kernel function my_kernel(A, MS)
    I = @index(Global)
    A[I] = 2 * A[I] + MS.b[1]
end

A = KA.ones(backend, DevFloat, 10, 10)
ev = my_kernel(backend, 64)(A, MS, ndrange=size(A))
KA.synchronize(backend)

A_cpu = Array(A)
test = all(A_cpu .≈ 4.0)
println("Test: ", test ? "Passed" : "Failed")
if test == false
    display(A)
end

