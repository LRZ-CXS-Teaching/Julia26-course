# Plotting and Curve Fitting

Julia has two quite flexible plotting modules, [`Plots`](https://docs.juliaplots.org/stable/) and [Makie](https://docs.makie.org/stable/). Let's focus on `Plots` here. The docu contains a nice tutorial as an introduction. Some short warm-up examples.
```julia
using Plots

# plot x*exp(-x) in the range [0,10]
plot(x->x*exp(-x),0,10)

# with title, label, x-axis and y-axis labels, different color
plot(x->x*exp(-x),0,10,title="Plot-Example", label="x*exp(-x)", xlabel="x", ylabel="y", color=:red)

# save to PDF file
savefig("example_plot.pdf")
```
`plot` returns a handle to the plot that can be used in savefig.
```julia
p = plot(x->x*exp(-x),0,10)
savefig(p, "example_plot.pdf")
```
`plot` has a huge and flexible interface (often overwhelming for beginners). Instead of the above, one can also use a range to set the points. Let's combine that also with plotting more than one graph in a single plot.
```julia
plot(0:1:10,x->x*exp(-x),label="with coarse resolution", linewidth=2)
plot!(0:0.01:10,x->x*exp(-x),label="with fine resolution", linewidth=2)
```
For the moment, the last thing to present is the error plot.
```julia
x = collect(0:1:10)                             # x values
f(x) = x*exp(-x)                                # f = x -> x*exp(-x)
yerr = 0.1 .* f.(x)                             # y-error (10% of function value) 
y = f.(x) .+ yerr .* randn(length(yerr))        # y values with small errors
plot(x,y,yerror=yerr, st=:scatter)              # scatter plot with error bars
```
<details>
  <summary>plot result</summary>

<div align="center">
  <img src="error-plot.png" width="600" alt="error graph plot">
</div>
</details>

Next to `plot`, there exist `scatter`, `histogram`, `heatmap`, ... and many more as convenience aliases to `plot`. The names are more telling. But `plot` also knows the `st` (`seriestype`). 

Furthermore, the different attributes like `xlabel` (`xl`), `ylabel` (`yl`) `linewidth` (`lw`),  etc. have short forms. 

Legend placement cat be done via `leg=:topleft`, etc. Remove legend, `leg=false`. `titlefont = (16, :red, :serif)` sets title font size, color and font style.

And much more ...

## Mandelbrot / Julia Sets

### Mandelbrot Sets
Mandelbrot sets can be created as follows. Take a point $c$ in the complex plane for the following iteration.
```math
z_i = z_{i-1}^2 + c\;,\qquad i = 1, 2, \ldots\;,\qquad z_0=0\;.
```
For some values of $c$, this iteration diverges, i.e. $|z_i|\rightarrow\infty$. For others, $|z_i|<\infty$ (it does not converge but follows some cycle, the magnitudes of which are limited). If somewhen $|z_i|>2$, the chance is high that the sequence diverges. Afaik, there is no exact limit known. Or, it cannot be predicted which $i$ this threshold is exceeded, or so.

It doesn't matter. We simply do the following. For each $c$, we iterate the sequence $z_i$ for $i$ from 1 to 100. If all $|z_i|\le2$, we assume convergence - and return 0. Otherwise, divergence - and for coloring, we return the index $i/100$ for $i$ for which $|z_i|>2$ (divided by 100, to get a number in $[0,1]$).

It is maybe fun to see that in Julia, we can do that in a single code line.
```julia
heatmap(-2:0.001:1,-1:0.001:1,(x,y)->(c=x+y*im; z=0+0im; for i in 1:100 z = z^2 + c; abs(z) > 2 && return i/100 end; 0), c = :magma, size=(1400,900), xl="real part", yl="imaginary part")
```
<details>
  <summary>plot result</summary>

<div align="center">
  <img src="mandelbrot.png" width="800" alt="Mandelbrot set">
</div>
</details>

#### Exercise
Zoom into some region of the set, and admire the structure.

### Julia Sets
Julia sets are quite similar. The difference is that $c$ is fix ... say $c=-0.8+0.156i$ (you can play with the value). But $z_0$ is now the point from the complex plane (the role, $c$ has in the Mandelbrot set). The rest is exactly the same.

#### Exercise
Create a plot of a Julia set. Zoom into details. Admire.

<details>
  <summary>Solution. (Don't cheat! Please try yourself first! It's easy!)</summary>
  
```julia
heatmap(-1.6:0.001:1.6,-1:0.001:1,(x,y)->(c=-0.8+0.156im; z=complex(x,y); for i in 1:100 z = z^2 + c; abs(z) > 2 && return i/100; end; 0), c=:haline, size=(1400,900))
```
<div align="center">
  <img src="juliaset.png" width="800" alt="Julia set">
</div>
</details>


## Curve Fitting

The general task: Given some data with uncertainties, e.g. from measurements, fit some parametric curves to it (not AI here!!).
In lack of real data, we'll create some for us in different ways (see below).

### Least Square Fitting (LsqFit)
The idea is simple. One has some data, $[x_i, y_i, \sigma_i]$ ($i=1,\ldots,N$), say from some measurement. $\sigma_i$ are the obtained uncertainties for the $y_i$'s. Next, you take some function, $f(x;a_1,a_2,\ldots)$, which also depends on some parameters, $a = a_1, a_2,\ldots$. "Least Squares" now means that one tries to minimize the sum of the quadratic differences between data and function with respect to these parameters (historically, it is often termed $\chi^2$ ... don't wonder).
```math
\chi^2(a) = \sum_{i=1}^N\left(\frac{y_i-f(x_i;a)}{\sigma_i}\right)^2 \rightarrow \text{min!} (\text{wrt. }a)\;.
```
In Julia, one can use e.g. the module [LsqFit](https://github.com/JuliaNLSolvers/LsqFit.jl) to accomplish this minimization (there are really quite more). The "model" is just a normal function, `f(x,a)`, in julia with `a` being possibly an array. E.g. `@. model(x,a) = a[1] + x*a[2]`.

The `curve_fit` function from `LsqFit` takes this model, and the data, and does the minimzation starting from some defined initial state of the parameters (please check the examples on their docu page). 

#### Exercise
Create some random data from some function - here a polynomial. (Once more using some DataFrame for convenient data handling, for instance.)
```julia
using Plots, DataFrames, Random
rng = Xoshiro(23423)
f(x) = 5x^3 - 4x^2 + 2.2x - 5.5
df = DataFrame([0:1.0:10],[:x])
transform!(df, :x => ByRow(x -> (y = f(x); yerr = y*0.1*randn(rng); return [y + yerr, abs(0.1*y)])) => [:y, :yerr])
plot(df.x,df.y,yerror=df.yerr, st = :scatter, markershape = :square, markercolor = :red, markeralpha = 0.8, label="measurement data")
```
In a next step, define a model with some parameters, and let `LsqFit` do the minimization for you.
```julia
@. model(x,a) = .... # TODO
using LsqFit
a0 = [0.,0.]                                      # initial value for as many parameters your model has
weights = 1.0 ./ (df.yerr .^ 2)                   # -> docu; just bear here with us
fit = curve_fit(model, df.x, df.y, weights, a0)
```
**Remark** `curve_fit` will require some weights based on the $\sigma_i$ (uncertainties). These are actually `weights[i]`$=1/\sigma_i^2$.

The result can be obtained via
```julia
a_opt = fit.param             # optimum parameters
a_se = standard_errors(fit)   # uncertainties of parameters
```
And you can add the result to the plot above
```julia
plot!(df.x, model(df.x, a_opt), label="weighted fit", lw=2, color=:red)
```

### Least Square Polynom Fitting (LinearAlgebra)
If it is about fitting some polynomial to data as we just exercised in the example above, an analytic solution actually exist to the $\chi^2$-minimization. As $f(x,a)$ depends linearly on the parameters (it's a polynomial!), one can easily form the derivative wrt. the $a_i$, and set
```math
\frac{\partial\chi^2}{\partial a_j} = 2\sum_{i=1}^N\frac{(y_i-a_1-a_2x-a_3x^2-\ldots)x^{j-1}}{\sigma_i^2}=0\;,\quad j=1,2,\ldots
```
If we define for some array $X_i$ ($i=1,\ldots,N$) the "average" (weighted by the $\sigma_i$'s) as
```math
\langle X\rangle = \sum_{i=1}^N\frac{X_i}{\sigma_i^2}
```
the above equation turns into the following linear system
```math
\begin{pmatrix}
\langle1\rangle & \langle x\rangle & \langle x^2\rangle & \ldots \\
\langle x\rangle & \langle x^2\rangle & \langle x^3\rangle & \ldots \\
\langle x^2\rangle & \langle x^3\rangle & \langle x^4\rangle & \ldots \\
\vdots & \vdots & \vdots & \ddots
\end{pmatrix}
\begin{pmatrix}
a_1\\
a_2\\
a_3\\
\vdots
\end{pmatrix}
=
\begin{pmatrix}
\langle y\rangle \\
\langle yx\rangle \\
\langle yx^2\rangle \\
\vdots
\end{pmatrix}
```
which can easily be solved using `LinearAlgebra` (`x = A\b`).

#### Exercise
Create some random data from some polynomial, say order three, and fit all polynomials of orders zero to four to it. (The 1st order fit is the "lineare regression line".)

### Bayes Curve Fitting -Tutorial (Turing, FlexiChains)
Bayes model (curve) fitting relies on the Bayes inference process (model -> parameter prior probability, data (likelihood) -> posterior). Look e.g. E. T. Jayes, "Probability - The Logic of Science", for a imho very good overview (but literature on Bayesianismis vast). 

After a posterior is obtained, it is usually analized using MCMC (Markov Chain Monte-Carlo) methods in order to obtain the expected parameters of the posterior distribution. (Mean values are minimizing the uncertainties as utility function -> Jaynes). Alternatively, one can also maximize the posterior wrt. to the fit parameters.

This process is automatable using Gibbs sampling such that packages like [BUGS](https://en.wikipedia.org/wiki/Bayesian_inference_using_Gibbs_sampling) and [JAGS](https://mcmc-jags.sourceforge.io/) could be developed to ease the application of Bayesian inference. In Julia, there are several module/packages for this purpose. We show here a [Turing](https://turinglang.org/) example, paired with [FlexiChains](https://github.com/penelopeysm/FlexiChains.jl) for the MCMC sampling and process control.

Consider the following short example. (Seriously, believe me! Much more complexity is easily achievable in this field!)

```julia
using Turing
using LinearAlgebra
using Plots
using FlexiChains

# define Bayes model using Turing's DSL
@model function fit_model(x, sigmas)
    a ~ Normal(0, 10.0)
    b ~ Normal(0, 10.0)
    c ~ Normal(0, 10.0)

    μ = a .* x.^2 .+ b .* x .+ c

    y ~ MvNormal(μ, Diagonal(sigmas.^2))
end

# example data with 10 points
const N = 10
x_data = collect(range(-5, 5, length=N))
sigma_data = rand(Uniform(0.5, 2.0), N)
true_p = [-1.0, 2.5, 0.8]                 # true parameters [c,b,a]
f(x;p) = p[1] + p[2]*x + p[3]*x^2         # true function underlying model p[1] == c, p[2] == b, p[3] == a
y_data = [f(x_data[i]; p=true_p) + rand(Normal(0, sigma_data[i])) for i in 1:N]

# define Bayes posterior : reads a bit like "model given data", P(model|data)
posterior = fit_model(x_data, sigma_data) | (; y = y_data)

# do sampling
chain = sample(posterior, NUTS(), 5000)

# show MCMC summary
stats = summarystats(chain)
display(stats)

# that's actually it ... rest is plotting

# evaluate parameter's MCMC statistics
using Statistics
a_samples = vec(chain[:a])
b_samples = vec(chain[:b])
c_samples = vec(chain[:c])
m_a = mean(a_samples)
m_b = mean(b_samples)
m_c = mean(c_samples)

# parameter uncertainties and covariance matrix if needed
#sd_a = std(a_samples)
#sd_b = std(b_samples)
#sd_c = std(c_samples)
#samples_matrix = hcat(a_samples, b_samples, c_samples)
#cov_matrix = cov(samples_matrix)

plot([-5:0.01:5],x -> f(x;p=true_p), label="original function")
plot!(x_data,y_data,yerror=sigma_data,st=:scatter, label="data with uncertainties")
plot!([-5:0.01:5],x -> f(x;p=[m_c,m_b,m_a]), label="fitted function")

savefig("bayes_result.pdf")
```

<details>
  <summary>Bayes inference fit result</summary>

<div align="center">
  <img src="bayes_result.png" width="600" alt="fit result plot">
</div>
</details>
