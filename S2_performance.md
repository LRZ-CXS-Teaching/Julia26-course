# Performance-related Topics and Performance Patterns

## General Considerations

> [!WARNING]
> **Rules for Optimization**
> * Measure and analyze performance before optimizing!
> * Optimize ONLY performance critical sections of code! ([20/80 rule](https://en.wikipedia.org/wiki/Pareto_principle))
> * First: CORRECT!!!   Second: Efficient! ([TDD](https://en.wikipedia.org/wiki/Test-driven_development))

Modern hardware is really complex (both CPUs and GPUs). Compilers and hardware use already quite some heuristics to analyze program flow and memory access patterns in order to optimally perform on the hardware, and to support programmers. However, nothing of that can work magic, either. And the hardware obliged (designed) to keep the `correct` semantics, primarily.

Julia is a strongly typed and natively to the hardware compiled language as is e.g. C/C++/Fortran. But Julia does that "just-in-time" - You write a code, Julia compiles it. You execute a Julia script, Julia compiles it. 
Julia supports programmers by adherence to certain programming styles and patterns, which need to be imposed explicitly in other programming languages (see e.g. Core Guidelines for C++). But still, as is valid for C/C++:

> [!WARNING]
> **Disclaimer**
> * Julia doesn't guarantee you performance!
> * But a good control over performance.

`@time` and [BenchmarkTools](https://juliaci.github.io/BenchmarkTools.jl/stable/) have already been mentioned. [Profile](https://docs.julialang.org/en/v1/manual/profile/) and [ProfileView](https://github.com/timholy/ProfileView.jl) can further help in complex software projects.

However,

> [!TIP]
> **How to write efficient Code**
> * The less code you write, not only the less the chance for bugs, but also the higher the chance for performance!

And,

> [!TIP]
> **Programming is Communication**
> * Remember that code is written mostly to be read - by oneself, or by others. (20/80 rule, again)
> * Adhere to efficient programming patterns! Know and understand your code! (Refactor often!)

(For a negative representation: [`How to write unmaintainable Code`](https://github.com/Droogans/unmaintainable-code))

> [!WARNING]
> **Keep Maintainability!**
> * Badly maintained code is very often (if not always) also badly performing.


Julia provides already a feature-rich syntax and a large and versatile module/package eco-system which makes a lot of even complex programming tasks very comprehensible. Search for them! Use them!
It's not a shame to use Google (or, even Google AI) for that.

A lot of Julia's power comes from its design to make even functions, types, and the code itself first class citizen objects in the language. Using macros, code can be auto-generated, or auto-annotated for whichever purposes. `@time` is one example. (E.g. see [Introduction to macros](https://www.youtube.com/watch?v=e6LGMeoQhfs) and/or [
Macros and Metaprogramming in Julia](https://www.youtube.com/watch?v=LPkB2GYoOZI))


## Special Patterns

### Constant Global Pattern (type stability)
Let's look at a simple scenario. We define a global variable, and two functions using it.
```julia
julia> var = 10
10

julia> f(x) = var + x
f (generic function with 1 method)

julia> g(x, y) = x + y
g (generic function with 1 method)
```
Let's now benchmark both functions.
```julia
julia> using BenchmarkTools

julia> @btime f(5);
  19.113 ns (0 allocations: 0 bytes)        # <-- !!

julia> @btime g(5,$var);                    # remember: variable interpolation in macros
  2.154 ns (0 allocations: 0 bytes)

julia> @btime g(5,10);
  1.202 ns (0 allocations: 0 bytes)
```
As reference, we also executed `g` with just the numbers, 5 and 10. So. What happened here? Let's have a look on the code using `@code_warntype`.
```julia
julia> @code_warntype f(5)
MethodInstance for f(::Int64)
  from f(x) @ Main REPL[3]:1
Arguments
  #self#::Core.Const(Main.f)
  x::Int64
Body::Any
1 ─ %1 = Main.:+::Core.Const(+)
│   %2 = Main.var::Any
│   %3 = (%1)(%2, x)::Any
└──      return %3
```
In the REPL, the color code is different. It is here just the syntax-highlighting that removed the color. The essential thing to note here, however, is that `Main.var::Any`. That is, the type of `var` is inferred as `Any`. Why is that so? Clearly,
```julia
julia> typeof(var)
Int64
```
It's an `Int64`! What's gone wrong then?

Simple answer: Julia compiles the functions just after pressing enter, and uses these functions then later. `f` incorporates the global variable `var`, which is then evaluated somewhen later, too. But then, at that future moment, `var` might have changed in between! It could even have a different type then! (To be honest, `var` is only a name, and points just to objects of some type at a time ...)
And the compiler must respect that this type might have changed (that's part of the philosophy of Julia to write as generic code as possible). So, it decides `var` inside `f` to of type `Any`. And only during runtime, it's converted to the type that it does have in fact then. This runtime conversion costs time!

Differently from e.g. C/C++ where a variable name is solidly assigned to a type, Julia allows more flexibility. But that comes at a price, obviously.

<br>

What can we do about it?

* Defining `f` via `f(x) = x + var::Int64` works. But this now makes the implicit contract that `var` is an `Int64`. If we changed `var = 10.0` to be a `Float64`, this function would be broken.
* `g(x,y)` showed already a way. Defining functions with an explicit argument list, and calling this function with the global variable makes it running only with local variables. The compiler compiles for each type of `var` another function. And infers there the current type. *type stability* does the rest.
* There is another solution. And from point of communication maybe even the best one. The major problem was that `var` is a *variable*, and could change anytime. The justified question is: "Is this really meant o be so?". More often than not, such *variables* are in fact *constants* - semantically. If that's the case, we should say so:
```julia
julia> const var = 10
10

julia> f(x) = var + x
f (generic function with 1 method)

julia> using BenchmarkTools

julia> @btime f(5);
  1.202 ns (0 allocations: 0 bytes)

julia> @code_warntype f(5)
MethodInstance for f(::Int64)
  from f(x) @ Main REPL[1]:1
Arguments
  #self#::Core.Const(Main.f)
  x::Int64
Body::Int64
1 ─ %1 = Main.:+::Core.Const(+)
│   %2 = Main.var::Core.Const(10)
│   %3 = (%1)(%2, x)::Int64
└──      return %3
```

In C++, this is called *const-correctnes*. It's probably a good idea to adhere to it. Judging code becomes not only easier for a compiler then, but also for other programmers reading this code.
In many cases, with this little information extra, compilers really can do some sort of magic in terms of code reduction during compilation - the maximum of performance optimization: "The fastest code is that one which doesn't need to execute at all." (the compiler can calculate things, too, and replaces the result immediately in the code, for instance).

### Beware of Temporaries
Let's look at the following innocously looking code.
```julia
function naiv_add(B, C, iterationen)
    A = zeros(size(B))
    for _ in 1:iterationen
        A = B + C                   # allocates each time anew
    end
    return A
end
```
Let's compare that with
```julia
function inplace_add(B, C, iterationen)
    A = zeros(size(B))
    for _ in 1:iterationen
        A .= B .+ C                 # 0 allocations, overwrite in-place
    end
    return A
end
```
Let's measure that using `BenchmarkTools`.
```julia
julia> B = rand(2000, 2000); C = rand(2000, 2000);

julia> @btime naiv_add($B, $C, 100);
  870.332 ms (303 allocations: 3.01 GiB)

julia> @btime inplace_add($B, $C, 100);
  655.145 ms (3 allocations: 30.52 MiB)
```
You may ask, what's the matter. Well, at some time, the Julia garbage collector is triggered. And this may *really* take some time to clean out all the temporaries.

In order to identify such problems, one can use `Profile` (together with `PProf`). If you find a time-dominant `wait()` in front of some "*gc_collect()" function, you face exactly this issue. 

### Struct of Arrays Pattern
Often, it's preferred to create a stucture like the following for convenience (we think in such structures).
```julia
struct Particle3D
    x::Float64
    y::Float64
    z::Float64
end
```
And as there are many of such particles, one needs a collection.
```julia
const N = 10_000_000
data = [Particle3D(rand(), rand(), rand()) for _ in 1:N]
```
In a MD simulation, one maybe needs to calculate the compute the respective distances. For simplicity of illustration, let's "only" determine the center-of-gravity (CoG) of the particle cloud.
```julia
function compute_center_of_gravity(particles)
    x², y², z² = [0., 0, 0]
    for i in eachindex(particles)
        @inbounds p = particles[i]     # no boundary checks
        x² += p.x^2
        y² += p.y^2
        z² += p.z^2
    end
    x = √(x²/length(particles))
    y = √(y²/length(particles))
    z = √(z²/length(particles))
    return [x,y,z]
end

a = compute_center_of_gravity(data)
```
Well, there is really nothing wrong. But only a bit inefficient for computers. In the next section, ["Parallelism-related Topics and Patterns"](S3_parallelism.md), we will explain a little more about this problem as it is related to memory access patterns of computers, and *cache lines* - the CPUs implicit parallelism.

Benchmarking of this gives (Intel Icelake).
```
--- Performance AoS (Standard Array) ---
  24.584 ms (2 allocations: 80 bytes)
```

Here, in short: Computers are better in accessing contiguous pieces of memory. And `data` has data in memory according to the pattern `data = [x1, y1, z1, x2, y2, z2, ...]`, which is a less optimal for this loop computation.

Certainly, letting `Particle3D` have three arrays, `x, y, z`, with the pattern, `x = [x_1, x2, ...], y = [y_1, y_2, ...], ...` would be better from computer's point of view. But implementing that from a user's perspective is maybe not so convenient. And it's not so easy to get it right.
```julia
struct ParticlePositions{A<:AbstractVector{Float64}}
  x::A
  y::A
  z::A
end

x_coords = rand(Float64, N)
y_coords = rand(Float64, N)
z_coords = rand(Float64, N)

soa_particles = ParticlePositions(x_coords, y_coords, z_coords)

function compute_center_of_gravity_soa(particles)
    return [√sum(particles.x.^2), √sum(particles.y.^2), √sum(particles.z.^2)] ./ length(particles.x)
end
```
First of all, we need another extra function to calculate the CoG. Second, it is way slower!! The benchmarking results in
```
--- Performance SoA (StructArray) ---
  78.799 ms (13 allocations: 228.89 MiB)
```
where immediately is clear what the issue is ... memory allocation for temporary arrays.

Ok. The function looks way shorter. Very compact. But what does it help?!

<br>

Let's look then what Julia already offers: `StructArrays`.
```julia
using StructArrays
using BenchmarkTools

struct Particle3D
    x::Float64
    y::Float64
    z::Float64
end

const N = 10_000_000

aos_data = [Particle3D(rand(), rand(), rand()) for _ in 1:N]
soa_data = StructArray(aos_data)                                     # makes a deep copy of aos_data!

function compute_center_of_gravity!(particles)                       # same function for AoS and SoA
    x², y², z² = (0, 0, 0)
    for i in eachindex(particles)
        @inbounds p = particles[i]                                   # no boundary checks
        x² += p.x^2
        y² += p.y^2
        z² += p.z^2
    end
    x = √(x²/length(particles))
    y = √(y²/length(particles))
    z = √(z²/length(particles))
    return [x,y,z]
end

println("--- Performance AoS (Standard Array) ---")
@btime compute_center_of_gravity!($aos_data);

println("\n--- Performance SoA (StructArray) ---")
@btime compute_center_of_gravity!($soa_data);
```
The result is
```
--- Performance AoS (Standard Array) ---
  24.938 ms (2 allocations: 80 bytes)

--- Performance SoA (StructArray) ---
  19.511 ms (2 allocations: 80 bytes)
```
A speed-up of 1.28 (speed-up = reference-execution-time / other-execution-time ; see next section).

There is still a tradeoff. `soa_data = StructArray(aos_data)` copies the AoS data into a new data structure. This means memory allocation! If one can dispense with the AoS data, and work only with the SoA data then, one can execute `aos_data = nothing; GC.gc()` in order to let the garbage collector remove the AoS data from memory. Also this requires some time!

### Memoization Pattern (idea)
Fibonacci numbers. $f_n = f_{n-1} + f_{n-2}$, $f_1 = f_0 = 1$. A notorious example for inefficient recursion.
```julia
julia> using BenchmarkTools

julia> fib(n) = n≤1 ? 1 : fib(n-1) + fib(n-2)
fib (generic function with 1 method)

julia> @btime fib(30)
  6.870 ms (0 allocations: 0 bytes)
```
Let's retry.
```julia
julia> using Memoization

julia> @memoize fibm(n) = n≤1 ? 1 : fibm(n-1) + fibm(n-2)
fibm (generic function with 1 method)

julia> @btime fibm(30)
  95.111 ns (0 allocations: 0 bytes)
```
That's better. 

Semantic: [Memoization pattern](https://en.wikipedia.org/wiki/Memoization) means to cache results that where already computed, in order to avoid re-computation. That's the trick. For possible implementation details, see e.g. the book of Kwong. 

### Barrier Function Pattern (type-unstable functions)
Let's look at the following function (example is taken from Kwong).
```julia
random_data(n) = isodd(n) ? rand(Int, n) : rand(Float64, n)
```
Yes! This works in julia! Types are first class citizens in Julia. Let's try that.
```julia
a = rand(Float64,10)
a_type = typeof(a)
if a_type <: AbstractArray{Float64, 1}
   println("AbstractArray{Float64, 1}")                 # synonym for some real code that executes here
else
   println("not a AbstractArray{Float64, 1}")
end
```
([RTTI](https://en.wikipedia.org/wiki/Run-time_type_information) in C++ is way more complicated.)

Moving right along. Let's write another function, which uses `random_data(n)`.
```julia
function double_sum_of_random_data(n)
    data = random_data(n)
    total = 0
    for v in data
       total += 2 * v
    end
    return total
end
```
Let's benchmark it.
```julia
julia> @btime double_sum_of_random_data(100000);
  430.250 μs (3 allocations: 781.32 KiB)                                         # Please remember!

julia> @btime double_sum_of_random_data(100001);
  75.269 μs (3 allocations: 781.38 KiB)                                          # Please remember!

julia> @code_warntype  double_sum_of_random_data(100000)
MethodInstance for double_sum_of_random_data(::Int64)
  from double_sum_of_random_data(n) @ Main REPL[2]:1
Arguments
  #self#::Core.Const(Main.double_sum_of_random_data)
  n::Int64
Locals
  @_3::Union{Nothing, Tuple{Float64, Int64}, Tuple{Int64, Int64}}                # Here are everywhere Unions!!
  total::Union{Float64, Int64}
  data::Union{Vector{Float64}, Vector{Int64}}
  v::Union{Float64, Int64}
Body::Union{Float64, Int64}
1 ─ %1  = Main.random_data::Core.Const(Main.random_data)
│         (data = (%1)(n))
│         (total = 0)
│   %4  = data::Union{Vector{Float64}, Vector{Int64}}                             # Type unkown at compile time!
│         (@_3 = Base.iterate(%4))
│   %6  = @_3::Union{Nothing, Tuple{Float64, Int64}, Tuple{Int64, Int64}}
│   %7  = (%6 === nothing)::Bool
│   %8  = Base.not_int(%7)::Bool
└──       goto #4 if not %8
2 ┄ %10 = @_3::Union{Tuple{Float64, Int64}, Tuple{Int64, Int64}}
│         (v = Core.getfield(%10, 1))
│   %12 = Core.getfield(%10, 2)::Int64
│   %13 = Main.:+::Core.Const(+)
│   %14 = total::Union{Float64, Int64}
│   %15 = Main.:*::Core.Const(*)
│   %16 = v::Union{Float64, Int64}
│   %17 = (%15)(2, %16)::Union{Float64, Int64}
│         (total = (%13)(%14, %17))
│         (@_3 = Base.iterate(%4, %12))
│   %20 = @_3::Union{Nothing, Tuple{Float64, Int64}, Tuple{Int64, Int64}}
│   %21 = (%20 === nothing)::Bool
│   %22 = Base.not_int(%21)::Bool
└──       goto #4 if not %22
3 ─       goto #2
4 ┄ %25 = total::Union{Float64, Int64}
└──       return %25
```
Julia needs to incorporate completely that different types can occur during runtime - depending on the input value function. And that for the full summation loop, too!
This prevents the JIT compiler from extra optimization.

The "*barrier function pattern*" (Kwong calls it so) is meant to cope with this issue. Let's look how it works. We outsource the loop computation into another function, `double_sum`.
```julia
function double_sum(data)
    total = 0
    for v in data
        total += 2 * v
    end
    return total
end
```
And we need to rewrite the `double_sum_of_random_data` function.
```julia
function double_sum_of_random_data(n)
    data = random_data(n)
    return double_sum(data)
end
```
Let's benchmark again.
```julia
julia> @btime double_sum_of_random_data(100000)
  212.368 μs (3 allocations: 781.32 KiB)                        # Compare with above!

julia> @btime double_sum_of_random_data(100001)
  45.616 μs (3 allocations: 781.38 KiB)                         # Compare with above!
```
Not bad! A factor of 2 speed-up!

What is the clue here? Julia can compile the `double_sum` function for each type (`Int64`, `Float64`) seperately. As there is no chance then to change the type anymore internally, it can apply all kinds of optimizations for the respective functions. Julia's multiple dispatch capability then does the rest.

Conclusion: Multiple dispatch is not merely a means of flexibility, but also an important means of optimization.
This can also be exploited to avoid ugly (and often inefficient) `if` conditions (`if type == Int64 do_this() else do_that() end`).


### Inlining
Function call have slight overhead (despite the statement about "first citizens" in julia). You can try to avoid by inlining functions in julia, where it makes sense, using the `@inline` macro. For instance,
```julia
julia> @inline g(x) = x^2
```
The function call is then *possibly* replaced by the function body directly.
"*possibly*": The compiler decides alone whether he really does it! And keep in mind that inlining might make debugging harder (as IPO/LTO does).


### Finale Remark
There are a lot of modules/packages out there that promise to be very convenient. And we do not recommend not to use them when they are appropriate. However, keep in mind that these modules need to be precompiled from time to time (when hardware changes - like on clusters, or when other packages are installed that interact with the former package, etc.) For large packages, this can be very time consuming. What is especially annoying if you CPU-budget is tight. Specifically in HPC, it is therefore advisable to avoid monster packages (`Images`, `Plots`, and many more etc.).
The practical stance is, measure the progress of your codes. If they appear too slow, check out why!

## Hands-on
Don't be confused. The hands-on may not be related to "performance" directly, but also to show Julia programming styles and patterns in real-life applications.

* [Containers and Algorithms (data handling patterns)](hands-on/S2/container_algorithms.md)
* [Plotting and Curve Fitting (Mandelbrot-/Julia-sets; 3 ways to fit curves to data)](hands-on/S2/plotting_and_fitting.md)
* [Operator Overloading](hands-on/S2/operator_overloading.md) (Julia's way to easy life - syntactic sugar)



