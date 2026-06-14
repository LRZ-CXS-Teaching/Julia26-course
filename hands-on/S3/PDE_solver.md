# Solving PDEs computationally (Tutorial)

## Introduction
Please look into the documentation of [`DifferentialEquations`](https://docs.sciml.ai/DiffEqDocs/stable/). There tutorials and examples. I guess, one cannot do better.

The simplest ODE standard example with still quite some complexit is probably the Lotka-Volterra model.
```math
\dot{u}(t) = \frac{d}{dt}
\begin{pmatrix}
x \\ y
\end{pmatrix}
=
\begin{pmatrix}
\alpha x - \beta xy \\ -\gamma y + \delta xy  
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
using DifferentialEquations
using Plots

# 1. System von Differentialgleichungen definieren (In-place Format)
function lotka_volterra!(du, u, p, t)
    x, y = u          # x: Beutepopulation, y: Räuberpopulation
    α, β, δ, γ = p    # Systemparameter
    
    du[1] = α * x - β * x * y      # Ableitung dx/dt
    du[2] = δ * x * y - γ * y      # Ableitung dy/dt
end

# 2. Anfangsbedingungen festlegen
u0 = [1.0, 1.0]       # Startpopulationen für [Beute, Räuber]

# 3. Zeitspanne für die Simulation definieren
tspan = (0.0, 20.0)   # Von t=0 bis t=20

# 4. Parameterwerte definieren
# α (Wachstum Beute), β (Jagdeffizienz), δ (Fortpflanzung Räuber), γ (Sterberate Räuber)
p = [1.5, 1.0, 1.0, 3.0]

# 5. Das ODEProblem-Objekt erstellen
prob = ODEProblem(lotka_volterra!, u0, tspan, p)

# 6. Die Gleichung numerisch lösen (Tsit5 ist ein moderner Standard-Solver)
sol = solve(prob, Tsit5())

# 7. Ergebnisse plotten
# Plot 1: Populationsentwicklung über die Zeit
p1 = plot(sol, labels=["Beute (x)" "Räuber (y)"], lw=2)
title!("Lotka-Volterra Zeitreihe")
xlabel!("Zeit (t)")
ylabel!("Population")

# Plot 2: Phasenzustandsraum (Räuber vs Beute)
p2 = plot(sol, vars=(1, 2), lw=2, legend=false)
title!("Phasenraum-Portrait")
xlabel!("Beute (x)")
ylabel!("Räuber (y)")

# Beide Plots nebeneinander anzeigen
plot(p1, p2, layout=(1, 2), size=(900, 400))

```
