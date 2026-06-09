# Performance-related Topics and Performance Patterns

## General Considerations

> [!WARNING]
> **Rules for Optimization**
> * Measure and analyze performance before optimizing!
> * Optimize ONLY performance critical sections of code! ([20/80 rule](https://en.wikipedia.org/wiki/Pareto_principle))
> * First: CORRECT!!!   Second: Efficient! (TDD)

Modern hardware is really complex (both CPUs and GPUs). Compilers and hardware use already quite some heuristics to analyze flow and memory access patterns in order to optimally perform on the hardware, and to support programmers. However, neither of them can work magic, either. And both are obliged to keep the `correct` semantics, primarily.

Julia is a strongly typed and natively to the hardware compiled language as is e.g. C/C++/Fortran. But Julia also supports programmers by adherence to certain programming styles and patterns, which need to be imposed explicitly in other programming languages (see e.g. Core Guidelines for C++). But still, as is valid for C/C++:

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


Julia provides already a feature-rich syntax and a large and versatile package eco-system which makes lot of even complex programming tasks very comprehensible. Search for them! Use them!
It's not a shame to use Google (or, even Google AI) for that.

A lot of Julia's power comes from it's design to make even functions, types, and the code itself first citizen objects in the language. Using macros, code can be auto-generated, or auto-annotated for whichever purposes. `@time` is one example. (E.g. see [Introduction to macros](https://www.youtube.com/watch?v=e6LGMeoQhfs) and/or [
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
  19.113 ns (0 allocations: 0 bytes)

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
In the REPL, the color code is different. It is here just the syntax-highlighting that removed the color. The essential thing to note here, however, is that `Main.var::Any`. That is the type of `var` is inferred as `Any`. Why is that so? Clearly,
```julia
julia> typeof(var)
Int64
```
It's an `Int64`! What's gone wrong then?

Simple answer: The REPL compiles the functions just after pressing enter, and uses these function then later. `f` incorporates the global variable `var`, which is then evaluated somewhen later. But then, at that moment, `var` might have been changed in between! It could have even a different type now! (To be honest, `var` is only a name, and points just to objects of some type ...)
And the compiler must respect that this type might have changed (that's part of the philosophy of Julia to write as generical code as possible). So, it decides `var` inside `f` to of type `Any`, which is then converted to the type that it has in fact during runtime. This conversion costs time!

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
In many cases, with this little information extra, compilers really can do some sort of magic in terms of code reduction during compilation - the maximum of performance optimization ("The fastest code is that one which doesn't need to execute at all.").


### Struct of Arrays Pattern

### Memoization Pattern (idea)

### Barrier Function Pattern (type-unstable functions) ?



## Hands-on
Don't be confused. The hands-on may not be related to Performance directly, but also to see Julia programming styles and patterns in real-life applications.

* Containers and Algorithms (data handling patterns)
* Plotting and Curve Fitting (Mandelbrot-/Julia-sets; 3 schemes to fit curves to data)
* Operator Overloading (Julia's way to easy life - syntactic sugar)



