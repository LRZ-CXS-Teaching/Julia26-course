## GEMM in Julia

The General Matrix Multiplication (GEMM) is a well-known problem in Linear Algebra:

```math
C = \alpha A * B + \beta C \quad \\[10pt]
A = (M, K) \;\, , \quad 
B = (K, N) \;\, , \quad 
C = (M, N)\\[10pt] 
\alpha, \beta \in \mathbb{R}
```

<br>

Let's consider the following simplified version, where $\alpha=1$, $\beta=0$ :

```math
C = A * B + C \quad \\[10pt]
A = (M,K) \;\, , \quad 
B = (K,N) \;\, , \quad 
C = (M,N)
```

In a manual naive implementation, that would look like:

```julia
for m in 1:M
    for k in 1:K
        for n in 1:N
            C[m, n] += A[m, k] * B[k, n]
        end
    end
end
```

BUT, as in many other programming language, depending on how the data of a matrix are stored in memory,
the loop order makes a HUGE difference in terms of performance.
E.g.: Fortran is column-major, C is row-major.

Have a look at the `./matmul_hands-on.jl` file: complete the `matmul_columnmajor!` and `matmul_rowmajor!`
functions with the appropriate loop order.
Then, run the benchmarking with:

```bash
julia> include("./matmul_hands-on.jl")
```

**QUESTION 1**: what does the benchmarking tell us about how Julia stores matrixes?

**QUESTION 2**: there are 2 native methods benchmarked; do they perform the same? (spoiler: no) why?