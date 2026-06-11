# 2D Heat Equation


## Math theory

### Continuous Formulation

The diffusion of heat in a two-dimensional domain is governed by the parabolic partial differential equation:

```math
\frac{\partial T}{\partial t} = D \left( \frac{\partial^2 T}{\partial x^2} + \frac{\partial^2 T}{\partial y^2} \right)
```

where $T(x,y,t)$ is the temperature field and $D$ is the thermal diffusivity constant.

<br>
<br>



### Discretization via Finite Difference (FTCS Scheme)

To solve this numerically on a computational grid, we apply the Forward-Time Central-Space (FTCS) finite difference method.

The continuous spatial domain is discretized into a uniform grid with spacing $\Delta x$ and $\Delta y$. 
The time domain is discretized with steps $\Delta t$. We denote the temperature at discrete coordinates as:

```math
T_{i,j}^n = T(x_i, y_j, t_n)
```

Applying a forward difference approximation for the time derivative yields:

```math
\frac{\partial T}{\partial t} \approx \frac{T_{i,j}^{n+1} - T_{i,j}^n}{\Delta t}
```

Applying a central difference approximation for the second-order spatial derivatives, 
assuming a uniform spatial grid where $\Delta x = \Delta y = h$:

```math
\frac{\partial^2 T}{\partial x^2} \approx \frac{T_{i+1,j}^n - 2T_{i,j}^n + T_{i-1,j}^n}{h^2}
```

```math
\frac{\partial^2 T}{\partial y^2} \approx \frac{T_{i,j+1}^n - 2T_{i,j}^n + T_{i,j-1}^n}{h^2}
```

<br>
<br>


### The 5-Point Stencil

Substituting the finite difference approximations back into the original partial differential equation yields the explicit update equation:

```math
\frac{T_{i,j}^{n+1} - T_{i,j}^n}{\Delta t} = D \left( \frac{T_{i+1,j}^n + T_{i-1,j}^n + T_{i,j+1}^n + T_{i,j-1}^n - 4T_{i,j}^n}{h^2} \right)
```

Isolating the future state $T_{i,j}^{n+1}$ and defining the dimensionless stability parameter $\alpha = \frac{D \Delta t}{h^2}$, we obtain the final explicit 5-point stencil equation to be implemented in the kernel:

```math
T_{i,j}^{n+1} = T_{i,j}^n + \alpha \left( T_{i+1,j}^n + T_{i-1,j}^n + T_{i,j+1}^n + T_{i,j-1}^n - 4T_{i,j}^n \right)
```

### Stability Condition (CFL)

For this explicit numerical scheme to remain mathematically stable, the Courant–Friedrichs–Lewy (CFL) condition strictly dictates that the parameters must satisfy:

```math
\alpha \le 0.25
```

Exceeding this value will result in numerical overflow and divergent oscillations during execution.

<br>
<br>



## TO-DO

We provide you a skeleton script containing the `heat_step_kernel!` function. 
You must complete the implementation by satisfying the following:

1. Fill the `heat_step_kernel!` function; more in details:
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



