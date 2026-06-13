# Ray- and Path-Tracing

## Ray-Tracing
Solution with threads. Replace the line
```julia
    for x in 1:camera.view_port_width, y in 1:camera.view_port_height
```
just by
```julia
   Threads.@threads :dynamic for (x, y) in collect(Iterators.product(1:camera.view_port_width, 1:camera.view_port_height))
```
`Iterator.product` and `collect` just merge the nested for-loop - a nested douple loop over `x` and `y`, respectively, becomes one loop over all pairs of `x` and `y`. The loop trip count is larger, and the scheduler can load-ballance better the work to the threads.

The program then needs to be run via `julia -t 4 raytracer.jl`. Result is the same.

## Path-Tracing
With threads, it is exactly like with the example above. 

Therefore, let's look at a fully parallel across many nodes example using `SlurmClusterManager` and `Distributed`.
<details>
  <summary>pathtrace_distributed_PPM.jl</summary>

```julia
using SlurmClusterManager
using Distributed

# Start workers via Slurm or fall back to local if not on a cluster
if !isempty(get(ENV, "SLURM_JOB_ID", ""))
    println("Start worker ...")
    flush(stdout)
    addprocs(SlurmManager())
    println("... Done")
    flush(stdout)
elseif nprocs() == 1
    println("No clue how I came here ...")
    flush(stdout)
    addprocs(4)
end

println("[MASTER] Successfully connected to $(nworkers()) workers.")
flush(stdout)

# 2. LIGHTWEIGHT LOADING ON ALL WORKERS
println("[MASTER] Loading basic packages on all workers...")
flush(stdout)
@everywhere using LinearAlgebra
@everywhere using Random

println("[MASTER] Loading ProgressMeter...")
flush(stdout)
@everywhere using ProgressMeter

# 3. DEFINE STRUCTS AND KERNELS ON ALL WORKERS
println("[MASTER] Defining structs and functions everywhere...")
flush(stdout)

@everywhere const Vec3 = Vector{Float64}

@everywhere struct Ray
  origin::Vec3
  direction::Vec3           # normalized to 1
end

@everywhere struct Material
  albedo::Vec3              # [R,G,B] in
  emission::Vec3            # [R,G,B] > 0
  roughness::Float64        # in
  metallic::Float64         # in
end

@everywhere struct Sphere
  center::Vec3
  radius::Float64           # > 0
  material::Material
end

@everywhere function random_in_unit_sphere()
  while true
    p = [rand()*2-1, rand()*2-1, rand()*2-1]
    if dot(p, p) < 1.0 return p end
  end
end

@everywhere function random_in_hemisphere(normal::Vec3)
  p = normalize(random_in_unit_sphere())
  return dot(p, normal) > 0.0 ? p : -p
end

@everywhere function reflect(v, n)
  return v - 2.0 * dot(v, n) * n
end

@everywhere function schlick_fresnel(cos_theta, f0)
  return f0 .+ (1.0 .- f0) .* (1.0 - cos_theta)^5
end

# --- Geometry ---
@everywhere function intersect(ray::Ray, s::Sphere)
  oc = ray.origin - s.center
  a = dot(ray.direction, ray.direction)
  b = 2.0 * dot(oc, ray.direction)
  c = dot(oc, oc) - s.radius^2
  discriminant = b^2 - 4*a*c
  if discriminant < 0 return -1.0 end
  t = (-b - sqrt(discriminant)) / (2.0*a)
  return t > 0.001 ? t : -1.0
end

# --- Illumination & Tonemapping ---
@everywhere function aces_tonemap(x::Vec3)
  a, b, c, d, e = 2.51, 0.03, 2.43, 0.59, 0.14
  @. clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0)
end

@everywhere function mix(a, b, t)
  return @. a * (1.0 - t) + b * t
end

# --- path tracer kernel ---
@everywhere function trace_path(ray::Ray, scene, depth::Int, include_emission::Bool=true)
  if depth <= 0 return [0.0, 0.0, 0.0] end    # maximum iteration reached, return black

  # find closest object intersecting with ray ... if any
  closest_t = Inf
  hit_obj = nothing
  for obj in scene
    t = intersect(ray, obj)
    if 0.001 < t < closest_t
      closest_t = t
      hit_obj = obj
    end
  end

  if hit_obj === nothing 
    # fancy color gradient background
    # scale y direction from [-1, 1] to
    t = 0.5 * (ray.direction[2] + 1.0)
#    t = 0.5 .* (ray.direction .+ 1.0)

    # color definition (RGB-values in HDR-space)
    horizon_color = [0.8, 0.9, 1.0]   # light blue at horizon
    zenith_color  = [0.1, 0.2, 0.5]   # dark blue at zenith

    # mix linearly between both colors -> gradient
    return mix(horizon_color, zenith_color, t)
  end 

  hit_point = ray.origin + ray.direction * closest_t
  normal = normalize(hit_point - hit_obj.center)
  mat = hit_obj.material
  
  # 1. emission (directly seen)
  result = include_emission ? mat.emission : [0.0, 0.0, 0.0]

  # 2. next event estimation (NEE; direct light)
  for obj in scene
    if sum(obj.material.emission) > 0 && obj !== hit_obj
      # sample point on light source (simplified: center)
      light_dir_full = obj.center - hit_point
      light_dist = norm(light_dir_full)
      light_dir = light_dir_full / light_dist
      
      # check shadows
      shadow_ray = Ray(hit_point, light_dir)
      in_shadow = false
      for s_obj in scene
          st = intersect(shadow_ray, s_obj)
          if 0.001 < st < light_dist - 0.001
              in_shadow = true; break
          end
      end

      if !in_shadow
          cos_l = max(0.0, dot(normal, light_dir))
          # diffusive fraction for light sources
          result += (mat.albedo ./ pi) .* obj.material.emission .* cos_l
      end
    end
  end

  # 3. indirect light (mirror vs. diffusiv)
  f0 = mix([0.04, 0.04, 0.04], mat.albedo, mat.metallic)
  f = schlick_fresnel(max(0.0, dot(-ray.direction, normal)), f0)
  
  if rand() < max(f...) # probability to mirror
    spec_dir = normalize(reflect(ray.direction, normal) + mat.roughness * random_in_unit_sphere())
    incoming = trace_path(Ray(hit_point, spec_dir), scene, depth - 1, true)  
    incoming_clamped = clamp.(incoming, 0.0, 20.0)    # catching fireflies

    result += f .* incoming_clamped
  else
    # diffusiv (unless fully metallic)
    if mat.metallic < 1.0
      diff_dir = random_in_hemisphere(normal)
      kd = (1.0 .- f) .* (1.0 - mat.metallic)
      indirect = trace_path(Ray(hit_point, diff_dir), scene, depth - 1, false)
      result += (mat.albedo .* indirect .* kd) # PDF & Lambert cut out each other in part in uniform sampling
    end
  end

  return result
end

println("[MASTER] All definitions broadcasted successfully.")
flush(stdout)

# --- szene & rendering ---
function render()
  w, h = 1280, 900                     # window width and height
  samples = 1024                        # samples per pixel
  exposure = 1.5                       # lighter image > 1
  depth = 12                            # number of bounces
  scale = 0.73                         # zoom factor

  scene = [
    Sphere([0,0,-1.0e6], 1.0e6-3.3, Material([0.5, 0.5, 0.5], [0,0,0], 0.1, 0.0)),       # ground
#    Sphere([0, 0, -1.5], 0.5, Material([1.0, 0.8, 0.2], [0,0,0], 0.05, 1.0)),  # golden sphere
    Sphere([7., -1., -1.], 1.0, Material([0.03, 1.0, 0.03], [0,0,0], 0.7, 0.6)),         # green
    Sphere([10.,0.,0.], 3.0, Material([1.0, 0.03, 0.03], [0,0,0], 0.7, 0.6)),            # red
    Sphere([5.,1.,1.],1.0, Material([0.03, 0.03, 1.0], [0,0,0], 0., 0.9)),               # blue
    Sphere([7.5, -2.7,  2.0], 0.7, Material([0.784, 0.784, 0.608], [0,0,0], 0.1, 0.7)),  # beige
    Sphere([8.5, -3.5,  0.0], 1.5, Material([1.0, 0.03, 1.0], [0,0,0], 0.3, 0.6)),       # magenta
    Sphere([-2., -10., 10.], 1., Material([0,0,0], [150, 150, 150], 0, 0))               # light source rear
  ]

  println("[MASTER] Starting distributed render loop...")
  flush(stdout)

  p = Progress(w; dt=1.0, desc="Rendering (Distributed)...")
  p_channel = RemoteChannel(() -> Channel{Bool}(Inf))

  @async while take!(p_channel)
      next!(p)
      flush(stdout) 
  end

  # Distributed loop reduction over columns using matrix addition (+)
  raw_img = @distributed (+) for x in 1:w
    local_img =  zeros(Float64, w, h, 3)
    
    for y in 1:h
      col = [0.0, 0.0, 0.0]
      for s in 1:samples
        u = -((x + rand() - w/2) / h ) * scale            # x pixel position
        v = -((y + rand() - h/2) / h ) * scale            # y pixel position
        ray = Ray([-1.5, 0, 0], normalize([1.0, u, v]))     
        col += trace_path(ray, scene, depth)              
      end
      
      # post-processing
      col /= samples                                      
      hdr_col = col .* exposure
      final_col = aces_tonemap(hdr_col) .^ (1.0 / 2.2)

      # Store components into the 3rd dimension
      local_img[x, y, 1] = final_col[1]
      local_img[x, y, 2] = final_col[2]
      local_img[x, y, 3] = final_col[3]

    end
    
    put!(p_channel, true) 
    local_img
  end

  put!(p_channel, false) 
  
  println("[MASTER] Distributed calculation finished. Saving final image to PPM file...")
  flush(stdout)

  # Save directly to an uncompressed PPM file (No external package dependency)
  open("path_traced_scene.ppm", "w") do io
      # PPM Header: P3 ASCII mode, width, height, max color intensity (255)
      println(io, "P3")
      println(io, "$w $h")
      println(io, "255")
      
      # Write data row-major (y first, then x) as required by the PPM standard
      for y in 1:h
          for x in 1:w
              r = round(Int, clamp(raw_img[x, y, 1], 0.0, 1.0) * 255)
              g = round(Int, clamp(raw_img[x, y, 2], 0.0, 1.0) * 255)
              b = round(Int, clamp(raw_img[x, y, 3], 0.0, 1.0) * 255)
              print(io, "$r $g $b    ")
          end
          println(io)
      end
  end

  println("[MASTER] Done!")
  flush(stdout)
end

render()
```
</details>

The similarity to the original code using `Images` is still visible. We needed to change the annotation with `@everywhere`, on order to load modules on the workers, and to make the functions known on the workers, which are supposed to run there. In `render`, we needed to parallelize the `ProgressMeter`, and annotate the mail loop with `@distributed (+)`. So, it became a reduction. Within the loop, each loop-chunk contains its own local image storage, which is not a RGB pixel matrix anymore, but just a linear `Array`, where the R, G, B values per pixel are just in sequence, $R_1, G_1, B_1, R_2, G_2, B_2,\ldots$ . And we diverted to the very simple graphics format [PPM](https://de.wikipedia.org/wiki/Portable_Anymap).

I've also added some more `println()` statments to see the progress of initialization in the Slurm job log output (`flush()` cares for releasing the caches - otherwise you may see nothing). It is a good idea for automated workflows to print as much debugging info as reasonably possible to early recognize ill states of jobs.

As usual for `Distributed` programs, it can be started via `julia -p 10 pathtrace_distributed_PPM.jl` (for instance, with 10 workers). Or, just within a Slurm job with the following script layout.
```shell
#!/bin/bash
#SBATCH -o log.%x.%j.%N.out
#SBATCH -D . 
#SBATCH -J pathtrace
#SBATCH --get-user-env 
#SBATCH --clusters=inter
#SBATCH --partition=cm4_inter
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=112             # the Slurm tasks are the Distributed workers
#SBATCH --hint=nomultithread
#SBATCH --mail-type=none 
#SBATCH --export=NONE                     # mandatory for reproducibility
#SBATCH --time=00:30:00 

module load slurm_setup                   # SBATCH header and this module are LRZ cluster specific (check site docu)

module load julia                         # make julia executable available

julia pathtrace_distributed_PPM.jl
```
That script was submitted just via `sbatch pathtrace_distributed_PPM.slurm`.
