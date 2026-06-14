# Solving PDEs computationally (Tutorial)

## Introduction
Please look into the documentation of [`DifferentialEquations`](https://docs.sciml.ai/DiffEqDocs/stable/). There tutorials and examples. I guess, one cannot do better.

The simplest ODE standard example with still quite some complexit is probably the Lotka-Volterra model (for predator-prey-relationship).
```math
\dot{u}(t) = \frac{d}{dt}
\begin{pmatrix}
x \\ y
\end{pmatrix}
=
\begin{pmatrix}
\alpha x - \beta xy \\
\delta xy -\gamma y  
\end{pmatrix}
\;,\qquad
u(t=0) = u_0 = 
\begin{pmatrix}
x_0 \\ y_0
\end{pmatrix}
=
\begin{pmatrix}
1 \\ 1
\end{pmatrix}
```
How can one solve it in Julia?
```julia
using DifferentialEquations, Plots

# 1. define ODE system (in-place format)
function lotka_volterra!(du, u, p, t)
    x, y = u          # x: prey population, y: predator population
    α, β, δ, γ = p    # system parameters
    
    du[1] = α * x - β * x * y      # dx/dt
    du[2] = δ * x * y - γ * y      # dy/dt
end

# 2. initial conditions (IC)
u0 = [1.0, 1.0]       # start populationen for [prey, predator]

# 3. define time span for simulation
tspan = (0.0, 20.0)   # t=0 till t=20

# 4. define system parameters
# α (prey growth rate), β (hunting efficiency), δ (reproduction rate predator), γ (mortality rate predator)
p = [1.5, 1.0, 1.0, 3.0]

# 5. ode problem object
prob = ODEProblem(lotka_volterra!, u0, tspan, p)

# 6. solving computationally (Tsit5 is a modern standard solver)
sol = solve(prob, Tsit5())

# 7. plot results
# Plot 1: population development over time
p1 = plot(sol, labels=["prey (x)" "predator (y)"], lw=2)
title!("Lotka-Volterra Time Series")
xlabel!("time (t)")
ylabel!("population")

# Plot 2: phase space (predator vs prey)
p2 = plot(sol, vars=(1, 2), lw=2, legend=false)
title!("Phase Space")
xlabel!("prey (x)")
ylabel!("predator (y)")

# both plots in one
plot(p1, p2, layout=(1, 2), size=(900, 400))
```
