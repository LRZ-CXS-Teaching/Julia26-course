# Operator Overloading - OOP (Tutorial)

Let's assume you need some mathatical 3D vector type that also can intuitively be used (like e.g. in Matlab). Dot and cross products with operators $\dot$ and $\cross$, respectively, so that we could simply write
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

## Task
Repeat that for the cross-product.
```math
v \times v = \begin{pmatrix}
      a_yb_z - a_zb_y \\
      a_zb_x - a_xb_z \\
      a_xb_y - a_yb_x
\end{pmatrix}
```
**Hint:**  `LinearAlgebra` also contains also already a `cross` function. Just do as for `dot`!
