# Julia 2026 course — Session 1: introduction

- [Julia 2026 course — Session 1: introduction](#julia-2026-course--session-1-introduction)
  - [1. `juliaup` and Julia installation](#1-juliaup-and-julia-installation)
  - [2. REPL basics](#2-repl-basics)
  - [3. Julia syntax essentials](#3-julia-syntax-essentials)
  - [4. Julia cool stuff](#4-julia-cool-stuff)
  - [5. A package worth mentioning: InteractiveUtils](#5-a-package-worth-mentioning-interactiveutils)
  - [6. BenchmarkTools intro (hands-on setup) (5 min)](#6-benchmarktools-intro-hands-on-setup-5-min)
    - [Example: benchmark native sum function vs manual implementation](#example-benchmark-native-sum-function-vs-manual-implementation)
    - [Example: benchmark sorting vector, save result to file and load it back](#example-benchmark-sorting-vector-save-result-to-file-and-load-it-back)
  - [Hands-on](#hands-on)

<br>
<br>





## 1. `juliaup` and Julia installation

- `juliaup` is the modern julia version manager; main commands here <https://github.com/JuliaLang/juliaup#using-juliaup>
  - `$ juliaup status`
  - `$ juliaup update`
  - `$ juliaup add <version>`
  - `$ juliaup default <version>`
- ALL JULIAUP IS CONTAINED UNDER `~/.juliaup` (by default, customizable with installation methods)
- ALL JULIA IS CONTAINED UNDER `~/.julia` (by default, customizable with `JULIAUP_DEPOT_PATH`/`JULIA_DEPOT_PATH`)

Example of customization of installation path:

```bash
# JULIAUP_DEPOT_PATH is the modern env var; sometimes the older JULIA_DEPOT_PATH is needed too
export JULIAUP_DEPOT_PATH="$HOME/.julia_aarch64"
export JULIA_DEPOT_PATH="$HOME/.julia_aarch64"
# we manually add juliaup bins to PATH (even if the next step does it automatically)
export PATH="/home/di75tom/.juliaup_aarch64/bin${PATH:+:${PATH}}"
# we install juliaup in custom location
curl -fsSL https://install.julialang.org | sh -s -- --path $HOME/.juliaup_aarch64`
# => juliaup will put julia in JULIAUP_DEPOT_PATH/JULIA_DEPOT_PATH
```

<br>
<br>




## 2. REPL basics


To start julia:

```bash
$ julia
$ julia +1.12       # run specific version
$ julia -t 4        # run julia with 4 threads
```

* Modes (from prompt):
  - `julia> ` : main mode
  - `?` => `help> ` : help mode
    - `??` => Extended help (active only for some functions)
  - `]` => `(@v1.12)>` : package mode
  - `;` => `shell> ` : shell mode
    - NOT A FULL SHELL: `; ls | grep smth` fails, pipe not supported 
    - workaround for pipes, in main mode: ```run(pipeline(`ls`, `grep`))```
    - BUT you can open a full shell with `; bash`... 
* go back to main mode: `Backspace` or `CtrlC`

<br>

Important keybindings in REPL:

* `^R` and `^S` : reverse and forward search
* `;` supresses stdout of command
* `Enter` runs a command IF COMPLETE, otherwise makes a newline
* `Meta-Enter` make a newline always
* `^D`, `^C`, `^L` as in the classical terminal

<br>

Pkg management:

- doable in main mode `using Pkg; Pkg.add("Plots")`, but better in Pkg mode
- `] activate`
  - `@v1.12` is a **base shared environment**
    - `] activate --shared @<Tab>` : see/activate shared envs
    - `~/.julia/environments` : location of all shared envs
    - `] activate @mysharedenv` : create your own shared env (but not base) => accessible everywhere
  - `] activate .` : creates a local project
- `] add Plots`, `] remove Plots`
- `] status`
- `] ?` for help of pkg mode

<br>
<br>
<br>




## 3. Julia syntax essentials

```julia
# single line comment
#=
multiline comment
=#
println("Hello world!")
1+1.                # Float
2^5                 # ^ is exponentiation
\lambda<Tab>        # greek lambda letter λ (\Lambda<Tab> capitalized Λ)
'\lambda<Tab>'      # return info and unicode
"\u03BB"            # prints λ
\euler<Tab> + \pi<Tab>
e\_1[TAB] = [1,0]
e\^1[TAB] = [1 0]
var=3.1415
ans                 # stores previous result

# strings
"string with interpolation: $var"
println("""a string $(1+var)""" * " with"^3 * " greetings.\n")  # without println, "\n" is not evaluted

# tuples, named tuples
animals = ("cats", "dogs", "penguins")      # TUPLES ARE IMMUTABLE
animals[1]
named_animals = (first = "cats", second = "dogs", whatever = "penguins")
named_animals.first

# dictionaries
phones = Dict("Matteo" => 123, "Martin" => "Not found")
phones["Matteo"]
haskey("Matteo",phones)
phones["Alice"] = 404
pop!(phones, "Martin")          # IMPORTANT "!" CONVENTION: FUNCTION MODIFIES INPUTS (at least one of them)
convert(Dict{String, Int64}, phones)


# arrays (1-INDEXED!!!)
fibonacci = [1, 1, 2, 3, 5, 8, 13]  # MUTABLE
push!(fibonacci, 21)
pop!(fibonacci)
shallow = fibonacci; shallow[1] = 404; fibonacci        # SHALLOW COPY
fibonacci[1] = 1
deep = copy(fibonacci); deep[1] = 11; fibonacci         # DEEP COPY
# matrixes (1-INDEXED!!!)
v = [ 1, 2, 3 ]                     # 3-element Vector{Int64}, I.E. 3×1 Matrix{Int64}
A = [ 1  2  3 ]                     # 1×3 Matrix{Int64}
B = [ 1 2 3; 4 5 6 ]                # 2×3 Matrix{Int64}
# slicing
C = rand(20,3)
C[1:2:10,:]


# functions
f(x) = √x             # \sqrt<Tab>
function f(x::Float64)
    @assert x > 0 "ERROR MESSAGE"
    sqrt(x)
end
(x -> x^2)(2)         # lambda function
g = x -> x^2          # "lambda-non-lambda" function
function h(a, b=2.0; c::Int=1, d)     # keyword arguments go after a semicolon
    return a+b*c/d
end
h(d=2, 1)


# bools, conditionals and ifs
x = 3.14
if ( 0 ≤ x < 5 && x%2 ==0 )
    println("idk")
elseif ( x < 0)
    println("idk pt.2")
else
    println("pt.3")
end
(3 > 0) && error("x cannot be greater than 0")
(3 > 0) ? println("hello") : println("again")       # ternary operator


# while loops
i=0
while i<10
  i+=1
  a=factorial(i)
  println("$i : $a")
end

# for loops
for i in 1:2:10           # start:step:stop
    print(i, " - ")
end
for s in ["a", "b", "c"]; println("el: $s"); end
# nested syntax — you CAN break the inner loop only
for i in 1:10
    print("i=$i   : j = ")
    for j in 1:10
        print("$j, ")
        j == 5 && break   # breaks inner loop, i continues
    end
    println("")
end
# compact syntax — break exits BOTH loops
for i in 1:10, j in 1:10
    println("i=$i j=$j")
    j == 5 && break       # exits everything
end
# comprehension list
v1 = [exp(-x^2) for x in range(1,10)]                                         # 10-element Vector{Float64}
v2 = [sin(a*x) for x in range(0, 2π, length=5), a in range(0, 1, length=3)]   # 5×3 Matrix{Float64}


# structs
struct Point
    x
    y
end
p = Point(1, 2.0)     # 1 will be converted to 1.0
# inside and outside constructor
struct Vec
    x::Float64
    y::Float64
    z::Float64
    function Vec(x, y, z)     # inside constructor => uses "new"
        (x ≥ 0) && (y ≥ 0) && (z ≥ 0) || error("x,y,z must be all be positive")
        new(x,y,z)
    end
end
Vec(x) = Vec(x,x,x)


# Modules; they are separate namespaces
using InteractiveUtils                      # BEST, all exported names are accessible 
# import InteractiveUtils: clipboard        # import only the listed name(s)
InteractiveUtils.?("somefile")[TAB]         # completion: list methods in the InteractiveUtils module that can be called on a string
InteractiveUtils.?("somefile")[SHIFT-TAB]   # same, but include methods where all arguments are typed as Any
max([1, 2], [TAB]                           # All methods where `Vector{Int}` matches as first argument
parentmodule(sin)                           # from which module this name comes from?
```

<br>
<br>




## 4. Julia cool stuff


**parametric types**:

```julia
struct Generic
    x
    y
end

struct Abstract
    x::Real
    y::Real
end

struct ParametricAbstract{T <: Real}
    x::T
    y::T
end

import Base: summarysize

a, b = 1.0f0, 2.0f0
println("Generic: ", summarysize(Generic(a, b)))                        # Generic: 24
println("Abstract: ", summarysize(Abstract(a, b)))                      # Abstract: 24
println("ParametricAbstract: ", summarysize(ParametricAbstract(a, b)))  # ParametricAbstract: 8
sizeof(a) + sizeof(b)                                                   # 8
(sizeof(a) + sizeof(b)) + 2*8                                           # 24, because also field pointers take 8 bytes each
```

<br>


**multiple dispatch**:


```julia
# simple example of multiple dispatch
describe(x::Int)     = "integer: $x"
describe(x::Float64) = "float with 2 decimals: $(round(x, digits=2))"
describe(x::String)  = "string of length $(length(x))"
describe(x::Bool)    = x ? "yes" : "no"


# more interesting example
abstract type Shape end
struct Circle <: Shape
    r                           # untyped => it can hold anything
end
struct Triangle <: Shape
    a::Float64
    b::Float64
    c::Float64
end
struct Ellipse <: Shape
    a::Float32
    b::Float32
end
struct Rectangle{T <: Real} <: Shape
    w::T
    h::T
end

area(x::Shape) = error("method not found!")
area(x::Circle) = π * x.r^2
area(x::Ellipse) = π * x.a * x.b
area(x::Rectangle) = x.w * x.h
area(x::Triangle) = (s = (x.a + x.b + x.c) / 2; return sqrt(s * (s - x.a) * (s - x.b) * (s - x.c)) )

perimeter(x::Shape) = error("method not found!")
perimeter(x::Circle) = 2π * x.r
perimeter(x::Rectangle) = 2 * (x.w + x.h)
perimeter(x::Triangle) = x.a + x.b + x.c

shapes = [
    Circle(1.0),
    Triangle(3.0, 4.0, 5.0),
    Rectangle(3, 4),
    Rectangle(3.0, 4.0),
    Ellipse(1.0, 2.0f0),
]

for s in shapes
    println(typeof(s), "   ", area(s), "   ", perimeter(s))
end
# Output:
#     Circle   3.141592653589793   6.283185307179586
#     Triangle   6.0   12.0
#     Rectangle{Int64}   12   14
#     Rectangle{Float64}   12.0   14.0
#     ERROR: method not found!
```

<br>

**Broadcasting**:

```julia
# broadcasting
A = rand(3,4)
B = ones(3,4)
f(x) = x + 1
f.(A)
A .+ B
sin.(A)
C = @. 2*A + B/2
```

<br>


Some more tricks:

```julia
##################################################52

# Regex and env vars

# <https://docs.julialang.org/en/v1/manual/strings/#man-regex-literals>
ENV                                                         # Dict containing key-value Pairs of all imported env vars
for (key,value) in ENV; println("$key : $value"); end       # print them all ...
ENV["SHELL"]                                                # "/bin/zsh"
filter(x->occursin(r"conda"i, x.first), ENV)                # case-insensitive search inside ENV keys

# list all names (functions, macros, consts, etc) of a module
names(InteractiveUtils)
filter(x->occursin(r"^code_", string(x)), names(InteractiveUtils, all=true))    # find only the names starting with "code_"
filter(contains(r"^code_"), string.(names(InteractiveUtils, all=true)))         # same as above

# julia help mode can search for regexes across all DOCSTRINGS (not only names) 
# (it's calling apropos under the hood)
?r"thread|task|Threads"     # find everything about threads
?r"^code_"                  # find all code_* macros and functions
apropos(r"^code_")          # same as above



##################################################52

# Numbers

# conversion and parsing
convert(Float64, 5)                 # change values between compatible data types
convert(Int64, floor(3.14))
parse(Int64, "5")                   # interprets a string as a number (or smth else)
@which parse                        # Base
eval(Meta.parse("1.3 + 5.6"))       # parse complex expressions

# min and max values of a numeric type (especially useful for integers)
typemax(Int64) + 1      # OVERFLOW
typemin(3) - 1          # OVERFLOW
# bigint
big(2)^64

# epsilon return the smallest float number ("epsilon") that can be added and considered
1.0 + eps(1.0)/2        # gives 1.0
# nextfloat (self-explanatory)
nextfloat(0.1)          # 0.10000000000000002
# binary representation
bitstring(0.1)          # "0011111110111001100110011001100110011001100110011001100110011010"

# KBN summation
t = [-1,1,1e-100]
sum(t)          # 0.0
] add KahanSummation
using KahanSummation
sum_kbn(t)      # 1e-100



##################################################52

# Miscellanea

# types
typeof(3)                   # concrete type of input 
eltype([1,2,3])             # type of the elements of a collection
isa(1, Number)              # whether x is of the given concrete type or its supertypes
2.0 isa Float64             # same as above 
Float64 <: Number           # whether x is subtype of y

# methods and dispatch
methods(sin)                # all methods for a generic function
@which sizeof               # in which module this input is defined?
@which sum([1, 2, 3])       # exact method selected by dispatch

# fields
fieldnames(typeof(1//2))            # fields of input object type (":num, :den")
getfield(1//2, :num)                # get ":num" field from input oject
setfield!(x, :num, 5)               # ERROR: immutable struct of type Rational cannot be changed

# size
sizeof(3)                                   # size, in bytes, of the canonical binary representation of the given
Base.summarysize([1, 2, 3])                 # amount of memory, in bytes, used by all unique objects reachable from the argument
# see the difference with following example
sizeof(Ref(rand(100))), Base.summarysize(Ref(rand(100)))

# references
v = [1,2,3]
r = Ref(v)              # "Base.RefValue{Vector{Int64}}([1, 2, 3])"
r[]                     # getting a value from a Ref, i.e. "[1, 2, 3]"
r[][2] = 7              # storing a new value in a Ref
r[]                     # "[1,7,3]"

# reassignments to scalars makes REBINDING (scalars are immutables)
x = 1; objectid(x)      # label "x" points to "1"
x +=2; objectid(x)      # rebinding of label "x", objectid changed
pointer_from_objref(x)  # ERROR: cannot be used on immutable objects
# IMMUTABLE OBJECTS DO NOT HAVE STABLE MEMORY ADDRESSES
# heap-allocated objects (arrays, strings) have stable memory address
v = [1, 2, 3]
pointer(v)              # Ptr{Int64}(0x0000000112b73ef0)        # native memory address of the data
pointer_from_objref(v)  # Ptr{Nothing}(0x0000000112281350)      # memory address of the Julia object reference itself (the header/metadata structure)

# @locals expands to a dictionary-like structure containing all local variables currently visible in scope
function f(x)
    y = x + 1
    z = y^2
    show(Base.@locals)
    return y+z
end

# infix operator |>, and native "ans" variable (stores previous result)
4*5 |> sin |> tan
ans |> x->x/3

# remove the three vertical dots from the output of a command
show(stdout, MIME"text/plain"(), names(InteractiveUtils, all=true))
```

<br>
<br>




## 5. A package worth mentioning: InteractiveUtils


```julia
using InteractiveUtils

# info
versioninfo(verbose=true)          # info about Julia version, env vars, etc
varinfo()                          # public global variables in the current scope (or in input module)

# type and method exploration
methodswith(String, InteractiveUtils; supertypes=true)      # array of methods with an argument of input type/its supertypes (in input module)
subtypes(Number)                                            # vector of direct subtypes of input type (down the type hierarchy)
supertypes(Int64)                                           # tuple of input type and all its supertypes (up the type hierarchy)

# source editing and definition lookup
ENV["JULIA_EDITOR"] = "/opt/homebrew/bin/nano"      # set default editor
edit("./file.jl")                                   # open input file with default editor
less("./file.jl")                                   # open input file with default pager
@less sort([3, 1, 2])                               # open pager at the chosen method definition
@edit my_func                                       # open editor at the source definition of "my_func"

# type stability check
@code_warntype sin(1.0) 
# performance introspection
@code_lowered sin(1.0)             # Lowered Julia IR
@code_typed sin(1.0)               # Inferred typed IR
@code_llvm sin(1.0)                # LLVM IR
@code_native sin(1.0)              # Native assembly

# helpers
clipboard("hello")                 # copy text to clipboard
apropos("@less")                   # help mode calls this under the hood; search available docstrings for entries containing pattern
```

<br>
<br>





## 6. BenchmarkTools intro (hands-on setup) (5 min)

<https://juliaci.github.io/BenchmarkTools.jl/stable/manual/>

In Base, `@time`, `@timev` etc are simple and useful, but always inferior to
the BenchmarkTools `@btime`, `@belapsed` etc and `@benchmark`.

Tutorial on `@benchmark` comparing native sum function vs a manual implementation
(same parameters are valid fot `@btime` etc)

```julia
using BenchmarkTools

function manual_sum(v)
    s = zero(eltype(v))
    @inbounds for x in v
        s += x
    end
    return s
end

v = rand(1000)

# ALWAYS CALL THE FUNCTION ONE TIME TO COMPILE IT
# Actually, it's not strictly necessary with Benchmarktools because it's smart,
# but it's still good practice
manual_sum(v)

# Bad benchmarks: includes global lookups
@benchmark manual_sum(v)
@benchmark manual_sum(rand(1000))

# Good benchmarks: variables are interpolated via $ => BenchmarkTools does not re-evaluate it
@benchmark manual_sum($v)
@benchmark manual_sum($(rand(1000)))

# you can manually tune benchmark params
@benchmark sum($v) samples=1000 evals=5     # 5 evaluations for each sample
```

<br>
<br>


### Example: benchmark native sum function vs manual implementation

```julia
using BenchmarkTools

function manual_sum(v)
    s = zero(eltype(v))
    @inbounds for x in v
        s += x
    end
    return s
end

v = rand(10_000)

manual_sum(s)

@benchmark manual_sum($v)
@benchmark sum($v)
```

<br>
<br>



### Example: benchmark sorting vector, save result to file and load it back


```julia
using BenchmarkTools

x = rand(10_000);

# NOTE: setup and teardown phases are executed for each sample, not each evaluation!
# <https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Setup-and-teardown-phases>
result = @benchmark sort!(y) setup=(y = copy($x))

BenchmarkTools.save("benchmark_sort.json", result)
res = BenchmarkTools.load("benchmark_sort.json")
res[1]
```


<br>
<br>
<br>



---


## Hands-on

Let's consider the following classical matrix multiplication:

```math
C = A * B + C \quad \\[10pt]
\mathrm{dim}(A) = M \times K \;\, , \quad 
\mathrm{dim}(B) = K \times N \;\, , \quad 
\mathrm{dim}(C) = M \times N \;\, , \quad 
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

**QUESTION 1**: What does the benchmarking tell us about how Julia stores matrixes?

**QUESTION 2**: There are 2 native methods benchmarked; do they perform the same? (spoiler: no) why?

