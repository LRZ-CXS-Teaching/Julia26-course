# Benchmark of matrix multiplication in julia
#     C = A * B + C
#     dims(C) = (M,N)
#     dims(A) = (M,K)
#     dims(B) = (K,N)
#
using LinearAlgebra
using BenchmarkTools
using Printf



function matmul_columnmajor!(C, A, B)
    M, K = size(A)
    _, N = size(B)
    #@inbounds for ... in ...                # FIX-ME!
    #    C[m, n] += A[m, k] * B[k, n]
    #end
    return nothing
end


function matmul_rowmajor!(C, A, B)
    M, K = size(A)
    _, N = size(B)
    #@inbounds for ... in ...                # FIX-ME!
    #    C[m, n] += A[m, k] * B[k, n]
    #end
    return nothing
end




function benchmark_matmul(M=512, n=0, k=0; dt=Float64)
    @assert (M > 0 && n >= 0 && k >= 0) "ERROR: M,N,K must be non-negative integers"
    K = k == 0 ? M : k
    N = n == 0 ? M : n
    A = rand(dt, M, K)
    B = rand(dt, K, N)
    C = zeros(dt, M, N)

    println("Matrix sizes of A, B, C (respectively): $(M)x$(K), $(K)x$(N), $(M)x$(N)  (all $dt) \n")

    println("\n\n\n---------- Manual column-major matmul ----------")
    t_col = @benchmark matmul_columnmajor!($C, $A, $B)
    display(t_col)

    fill!(C, 0.0)

    println("\n\n\n---------- Manual row-major matmul ----------")
    t_row = @benchmark matmul_rowmajor!($C, $A, $B)
    display(t_row)

    fill!(C, 0.0)

    println("\n\n\n---------- Native mul! ----------")
    t_mul = @benchmark mul!($C, $A, $B)
    display(t_mul)

    fill!(C, 0.0)

    println("\n\n\n---------- Native * ----------")
    t_star = @benchmark $C = $A * $B
    display(t_star)

    res = [
        ("column-major",    median(t_col).time),
        ("row-major",       median(t_row).time),
        ("native mul!",     median(t_mul).time),
        ("native *",        median(t_star).time),
    ] 

    native_star_median = only(filter(x->x[1]=="native *", res))[2]
    res_sorted = sort(res, by = x->x[2])
    println("\n\n\nMedian times and ratio wrt native * one:")
    for entry in res_sorted
        @printf("  %14s | %12f | %12f\n", entry[1], entry[2]/1e9, entry[2]/native_star_median)        
    end

end

benchmark_matmul(100)
