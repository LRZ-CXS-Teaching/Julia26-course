# Plotting and Curve Fitting

## Curve Fitting

### Least Square Fitting (LsqFit)
```julia
using Plots, DataFrames, Random
rng = Xoshiro(23423)
f(x) = 5x^3 - 4x^2 + 2.2x - 5.5
df = DataFrame([0:1.0:10],[:x])
transform!(df, :x => ByRow(x -> (y = f(x); yerr = y*0.1*randn(); return [y + yerr, abs(0.1*y)])) => [:y, :yerr])
plot(df.x,df.y,yerror=df.yerr, st = :scatter, markershape = :square, markercolor = :red, markeralpha = 0.8, label="measurement data")

using LsqFit
@. model(x, p) = p[1] + p[2] * x + p[3] * x^2 + p[4] * x^3
weights = 1.0 ./ (df.yerr .^ 2)
p0 = [0.0, 0.0, 0.0, 0.0]
fit = curve_fit(model, df.x, df.y, weights, p0)
p_opt = fit.param
p_se = standard_errors(fit)
plot!(df.x, model(df.x, p_opt), label="weighted fit", lw=2, color=:red)
```
