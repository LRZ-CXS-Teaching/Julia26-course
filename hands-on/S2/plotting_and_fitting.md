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
Next to `plot`, there exist `scatter`, `histogram`, `heatmap`, ... and many more as convenience aliases to `plot`. The names are more telling. But `plot` also knows the `st` (`seriestype`). 

Furthermore, the different attributes like `xlabel` (`xl`), `ylabel` (`yl`) `linewidth` (`lw`),  etc. have short forms. 

Legend placement cat be done via `leg=:topleft`, etc. Remove legend, `leg=false`. `titlefont = (16, :red, :serif)` sets title font size, color and font style.

And much more ...

## Mandelbrot / Julia Sets

### Mandelbrot Sets

```julia
heatmap(-2:0.001:1,-1:0.001:1,(x,y)->(c=x+y*im; z=0+0im; for i in 1:100 z = z^2 + c; abs(z) > 2 && return i/100 end; 0), c = :magma, size=(1400,900), xl="x", yl="y")
```

### Julia Sets


## Curve Fitting

The general task: Given some data with uncertainties, e.g. from measurements, fit some parametric curves to it (not AI here!!).
In lack of real data, we'll create some for us in different ways (see below).

### Least Square Fitting (LsqFit)



### Least Square Polynom Fitting (LinearAlgebra)


### Bayes Curve Fitting (Turing, FlexiChains)
