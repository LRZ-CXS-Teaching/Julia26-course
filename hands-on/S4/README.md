# 2D Heat Equation


## Math theory

Sources:

- <https://en.wikipedia.org/wiki/Heat_equation>
- <https://en.wikipedia.org/wiki/FTCS_scheme>
- <https://en.wikipedia.org/wiki/Finite_difference_method>
- <https://en.wikipedia.org/wiki/Von_Neumann_stability_analysis>

<br>
<br>


### Continuous Formulation

The [Heat Equation](https://en.wikipedia.org/wiki/Heat_equation) in a two-dimensional domain is governed by this partial differential equation:

```math
\frac{\partial T}{\partial t} = D \left( \frac{\partial^2 T}{\partial x^2} + \frac{\partial^2 T}{\partial y^2} \right) \quad \quad (1)
```

where $T(x,y,t)$ is the temperature field and $ D$ is the thermal diffusivity constant.

<br>
<br>



### Discretization via Finite Difference (FTCS Scheme)

To solve this numerically on a computational grid, we apply the [Forward-Time Centrered-Space (FTCS)](https://en.wikipedia.org/wiki/FTCS_scheme) method, which is a [Finite Difference Metho](https://en.wikipedia.org/wiki/Finite_difference_method):

1. we discretize the spatial domain into a uniform grid, with spacing $\Delta x = \Delta y = h$
2. we discretize the time domain with steps $\Delta t$
3. we denote the temperature at discrete coordinates as: $T_{i,j}^n = T(x_i, y_j, t_n)$
4. we apply a forward difference approximation for the time derivative and a central difference approximation for the second-order spatial derivative

```math
\frac{\partial T}{\partial t} \approx \frac{T_{i,j}^{n+1} - T_{i,j}^n}{\Delta t} \quad \quad \quad (2a)
\\[10pt]
\frac{\partial^2 T}{\partial x^2} \approx \frac{T_{i+1,j}^n - 2T_{i,j}^n + T_{i-1,j}^n}{h^2} \quad \quad \quad (2b)
\\[10pt]
\frac{\partial^2 T}{\partial y^2} \approx \frac{T_{i,j+1}^n - 2T_{i,j}^n + T_{i,j-1}^n}{h^2} \quad \quad \quad (2c)
```

<br>
<br>



We substitute the previous three finite difference approximations back into the original heat equation:

```math
(2a),(2b),(2c) \; \mathrm{in} \; (1) \quad \Rightarrow \quad
\frac{T_{i,j}^{n+1} - T_{i,j}^n}{\Delta t} = D \left( \frac{T_{i+1,j}^n + T_{i-1,j}^n + T_{i,j+1}^n + T_{i,j-1}^n - 4T_{i,j}^n}{h^2} \right)
\quad \quad \quad (3)
```

We then isolate the future state $T_{i,j}^{n+1}$, we define the dimensionless stability parameter $\alpha = \frac{D \Delta t}{h^2}$ and we get 
final explicit 5-point stencil equation to be implemented in the kernel:


```math
(3) \; \Rightarrow \; T_{i,j}^{n+1} - T_{i,j}^n = D \, \Delta t\left( \frac{ T_{i+1,j}^n + T_{i-1,j}^n + T_{i,j+1}^n + T_{i,j-1}^n - 4T_{i,j}^n }{h^2} \right)
```


```math
\Rightarrow \quad T_{i,j}^{n+1} = T_{i,j}^n + \alpha \left( T_{i+1,j}^n + T_{i-1,j}^n + T_{i,j+1}^n + T_{i,j-1}^n - 4T_{i,j}^n \right) \quad , \quad \alpha = \frac{D \Delta t}{h^2} \quad \quad \quad (4)
```

Essentially, for every cell (red in the following grid), we'll need to consider the values of the 4 surroundings cells (green):

<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
  <rect x="80" y="40" width="40" height="40" fill="lightgreen"/>
  <rect x="40" y="80" width="40" height="40" fill="lightgreen"/>
  <rect x="80" y="80" width="40" height="40" fill="red"/>
  <rect x="120" y="80" width="40" height="40" fill="lightgreen"/>
  <rect x="80" y="120" width="40" height="40" fill="lightgreen"/>
  <g stroke="#999" stroke-width="1">
    <line x1="0" y1="0" x2="200" y2="0"/><line x1="0" y1="40" x2="200" y2="40"/>
    <line x1="0" y1="80" x2="200" y2="80"/><line x1="0" y1="120" x2="200" y2="120"/>
    <line x1="0" y1="160" x2="200" y2="160"/><line x1="0" y1="200" x2="200" y2="200"/>
    <line x1="0" y1="0" x2="0" y2="200"/><line x1="40" y1="0" x2="40" y2="200"/>
    <line x1="80" y1="0" x2="80" y2="200"/><line x1="120" y1="0" x2="120" y2="200"/>
    <line x1="160" y1="0" x2="160" y2="200"/><line x1="200" y1="0" x2="200" y2="200"/>
  </g>
</svg>

<br>
<br>



**NOTE:** the [von Neumann stability analysis](https://en.wikipedia.org/wiki/Von_Neumann_stability_analysis) for the two-dimensional heat equation dictates that the FTCS method is numerically stable if and only if:

```math
\Delta t \leq \frac{1}{2D \left(\frac{1}{\Delta x^2} + \frac{1}{\Delta y^2}\right)} \quad \quad \quad (5)
```

Using our previous definition of $\alpha = \frac{D \Delta t}{h^2}$ and $\Delta x = \Delta y = h$:

```math
\Rightarrow \quad \Delta t \leq \frac{1}{2D \left(\frac{1}{h^2} + \frac{1}{h^2}\right)}
\\[10pt]
\Rightarrow \quad \Delta t \leq \frac{h^2}{4D}
\\[10pt]
\Rightarrow \quad \frac{D \Delta t}{h^2} \leq \frac{1}{4}
\\[10pt]
\Rightarrow \quad \alpha \leq 0.25 \quad \quad (6)
```

Exceeding this value of $\alpha = 0.25$ will result in numerical overflow and divergent oscillations during execution.

<br>
<br>



## TO-DO

We provide you a skeleton script containing the `heat_step_kernel!` function. 
You must complete the implementation by satisfying the following:

1. Fill the `heat_step_kernel!` function with the Eq. (4); more in details:
    * extract the Cartesian $(i, j)$ 2D thread index; have a look at the julia help page for `@index`
    * to define the boundaries, we need to extract the spatial bounds `Nx` and `Ny` of the input array
    * the 5-point stencil algorithm fundamentally requires read access to neighboring cells $(i\pm1, j\pm1$
      * => evaluating the stencil on the matrix perimeter will trigger out-of-bounds memory violations
      * => implement a conditional check to restrict the computation strictly to the interior points 
    * translate the final mathematical stencil equation into Julia syntax
      * map $T_{i,j}^{n+1}$ to the output array (`T2`) and $T_{i,j}^n$ to the input array (`T1`)
      * prefix the assignment with the `@inbounds` macro, to instructs the compiler to bypass runtime bounds checking inside the kernel loop, a mandatory step for achieving acceptable GPU performance

2. run the script to compare your kernel with the `cpu_reference_step!` function (pure CPU implementation)

3. add proper GPU backend
   * select the correct backend package for your available hardware (e.g., `CUDA` for NVIDIA GPUs, `AMDGPU` for AMD)
   * explicitly migrate the initialized CPU memory to the correct GPU array
   * launch again the wrapper function
   * pull the resultant array back to host memory via `Array(...)`
   * execute the validation assertions against the CPU reference output



