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

### Least Square Polynom Fitting (LinearAlgebra)
```julia
using Random, Plots, Distributions

f(x) = 4.3 + 2.5x - 3.2x^2 + 0.3x^3 

xvs = collect(0.0:10)
σ   = rand(Uniform(0.5,5.0),length(xvs))
# yvs = [f(xvs[i]) + σ_i[i]*randn() for i in 1:length(xvs)]
# or, shorter
# yvs = f.(xvs) .+ randn.() .* σ
# or, even shorter
@. yvs = f(xvs) + randn() * σ

plot(f,minimum(xvs),maximum(xvs),label="exact",linewidth=2)
plot!(xvs,yvs,yerror=σ,st=:scatter,label="data")

using LinearAlgebra

g(n; x=xvs, y=yvs, σ=σ) = sum(yvs.*xvs.^n./σ.^2)
h(n; x=xvs, σ=σ) = sum(xvs.^n./σ.^2)

xs = [h(n) for n=0:2*5]
ys = [g(n) for n=0:5]

# polynom deg 0
const Xval = ys[1]/xs[1]
f0(x;X=Xval) = X

# polynom deg 1
const A = [ xs[1] xs[2]; 
            xs[2] xs[3]]
const b = [ ys[1]; 
            ys[2]]
const X1 = A\b
f1(x; X=X1) = X[1] + X[2]*x

# polynom deg 2
const A = [ xs[1] xs[2] xs[3]; 
            xs[2] xs[3] xs[4]; 
            xs[3] xs[4] xs[5]]
const b = [ ys[1]; 
            ys[2]; 
            ys[3]]
const X2 = A\b
f2(x;  X=X2) = X[1] + X[2]*x + X[3]*x^2

# polynom deg 3
const A = [ xs[1] xs[2] xs[3] xs[4]; 
            xs[2] xs[3] xs[4] xs[5]; 
            xs[3] xs[4] xs[5] xs[6]; 
            xs[4] xs[5] xs[6] xs[7]]
const b = [ ys[1]; 
            ys[2]; 
            ys[3]; 
            ys[4]]
const X3 = A\b
f3(x;  X=X3) = X[1] + X[2]*x + X[3]*x^2 + X[4]*x^3

# polynom deg 4
const A = [ xs[1] xs[2] xs[3] xs[4] xs[5]; 
            xs[2] xs[3] xs[4] xs[5] xs[6]; 
            xs[3] xs[4] xs[5] xs[6] xs[7]; 
            xs[4] xs[5] xs[6] xs[7] xs[8];
            xs[5] xs[6] xs[7] xs[8] xs[9];]
const b = [ ys[1]; 
            ys[2]; 
            ys[3]; 
            ys[4];
            ys[5]]
const X4 = A\b
f4(x;  X=X4) = X[1] + X[2]*x + X[3]*x^2 + X[4]*x^3 + X[5]*x^4


plot!(f0,minimum(xvs),maximum(xvs),label="fit deg 0")
plot!(f1,minimum(xvs),maximum(xvs),label="fit deg 1")
plot!(f2,minimum(xvs),maximum(xvs),label="fit deg 2")
plot!(f3,minimum(xvs),maximum(xvs),label="fit deg 3", linewidth=2)
plot!(f4,minimum(xvs),maximum(xvs),label="fit deg 4")

savefig("fit_result.pdf")
```
