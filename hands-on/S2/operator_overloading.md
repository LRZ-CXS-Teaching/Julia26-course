# Operator Overloading (Tutorial)

Let's assume you need some mathatical 3D vector type that also can intuitively be used (like e.g. in Matlab). Dot and cross products with operators $\cdot$ and $\times$, respectively, so that we could simply write
```julia
v₁ = vec3(1,2,3)
v₂ = vec3(3,2,1)
s = v₁ ⋅ v₂             # dot product
v₃ = v₁ × v₂            # cross product
```
Can one easily achieve that?

Indeed, it is feasible. [`LinearAlgebra`](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/) implements quite a lot already, and one can intuitively use it like in school.
```julia
using LinearAlgebra

struct Vec3                    # a structure
    x::Float64
    y::Float64
    z::Float64
end

# import dot-function from LinearAlgebra for extension
import LinearAlgebra: dot
dot(v1::Vec3, v2::Vec3) = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

v₁ = Vec3(1, 2, 3)
v₂ = Vec3(3, 2, 1)

s = v₁ ⋅ v₂             # result: 10.0
```

### Exercise
Repeat that for the cross-product.
```math
a \times b = \begin{pmatrix}
      a_yb_z - a_zb_y \\
      a_zb_x - a_xb_z \\
      a_xb_y - a_yb_x
\end{pmatrix}
```
**Hint:**  `LinearAlgebra` contains already a `cross` function. Just do as for `dot`!

<details>
    <summary>Solution</summary>

```julia
import LinearAlgebra: cross
function cross(v1::Vec3, v2::Vec3)
    return Vec3(
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )
end

v₁ = Vec3(1, 2, 3)
v₂ = Vec3(3, 2, 1)
v₃ = v₁ × v₂                         # result: Vec3(-4.0, 8.0, -4.0)
v₁ ⋅ v₃ == 0                         # true
v₂ ⋅ v₃ == 0                         # true
```
</details>

If you want to overload also `+`, `-`, `*`, ... etc. they are from `Base`. (That's a bit confusing ... Simply consult Google.)
```julia
import Base: +, -, *

# addition of two vectors
+(v1::Vec3, v2::Vec3) = Vec3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)

# subtraktion of two vectors
-(v1::Vec3, v2::Vec3) = Vec3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)

# scalar multiplication from left
*(a::Real, v::Vec3) = Vec3(a * v.x, a * v.y, a * v.z)

# scalar multiplication from right
*(v::Vec3, a::Real) = a * v                           # good practice: implementation in terms of another - code reuse; single point of change/failure
```

What else? Custom IO for user-defined types?
```julia
struct Person
    name::String
    surname::String
    age::UInt64
end

p₁ = Person("John","Doe",42)

println(p₁)                  # result: Person("John", "Doe", 0x000000000000002a)
```
Let's have it nicer.
```julia
Base.show(io::IO, z::Person) = print(io,z.name," ",z.surname," is ",z.age," years old.")

println(p₁)                  # result: John Doe is 42 years old.
```

And more, and more, ... 
