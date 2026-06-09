# Performance-related Topics and Performance Patterns

## General Considerations

> [!WARNING]
> **Rules for Optimization**
> * Measure and analyze performance before optimizing!
> * Optimize ONLY performance critical sections of code! (20/80 rule)
> * First: CORRECT!   Second: Efficient.
> * Adhere to efficient programming patterns!

Modern hardware is really complex (both CPUs and GPUs). Compilers and hardware use already quite some heuristics to analyze flow and memory access patterns in order to optimally perform on the hardware, and to support programmers. However, neither of them can work magic, either. And both are obliged to keep the `correct` semantics, primarily.

Julia is a strongly typed and natively to the hardware compiled language as is e.g. C/C++/Fortran. But Julia also supports programmers by adherence to certain programming styles and patterns, which need to be imposed explicitly in other programming languages (see e.g. Core Guidelines for C++). But still, as is valid for C/C++:

> [!WARNING]
> **Disclaimer**
> * Julia doesn't guarantee you performance!
> * But a good control over performance.

`@time` and [BenchmarkTools](https://juliaci.github.io/BenchmarkTools.jl/stable/) habe already been mentioned. [Profile](https://docs.julialang.org/en/v1/manual/profile/) and [ProfileView](https://github.com/timholy/ProfileView.jl) can further help in complex software projects.

However,

> [!TIP]
> **How to write efficient Code**
> * The less code you write, not only the less the chance for bugs, but also the higher the chance for performance!

Julia provides already a feature-rich syntax and a large and versatile package eco-system which makes lot of even complex programming tasks very comprehensible. Search for them! Use them!
It's not a shame to use Google (or, even Google AI) for that.

A lot of Julia's power comes from it's design to make even functions, types, and the code itself first citizen objects in the language. Using macros, code can be auto-generated, or auto-annotated for whichever purposes. `@time` is one example. (E.g. see [Introduction to macros](https://www.youtube.com/watch?v=e6LGMeoQhfs) and/or [
Macros and Metaprogramming in Julia](https://www.youtube.com/watch?v=LPkB2GYoOZI))


## Special Patterns

### Constant Global Pattern (type stability)



## Hands-on
