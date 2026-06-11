# Ray- and Path-Tracing

3D visualization is certainly one of the most fascinating applications in computer science, and certainly deserve some exta lectures. For this course, the time would never suffice to do that cautiously. 
Therefore, two examples below are not meant to be an introduction to any of the tracing methods, but only as an illustration of how "simple" such programs can be written in Julia.

The second thing is your task.

**Parallelize the Main-Loop!** Either with threads, or with workers. In principle, you can also use MPI for that.

## Ray-Tracing
The program is as follows.

<details>
  <summary>raytrace.jl</summary>

```julia
using Colors, Images

# -------------- geometry objects ----------------------

# 3D points and vectors
struct Vec3{T}   # parametric type to enforce type consistency
  x::T
  y::T
  z::T
end

Base.show(io::IO, v::Vec3) = print(io, "(", v.x, ",", v.y, ",", v.z, ")")

Base.:+(v::Vec3, w::Vec3) = Vec3(v.x+w.x, v.y+w.y, v.z+w.z)      # vec addition
#Base.:+(v::Vec3{T}, w::Vec3{T}) where {T} = Vec3{T}(v.x+w.x, v.y+w.y, v.z+w.z)      # enforces type consistency
Base.:-(v::Vec3, w::Vec3) = Vec3(v.x-w.x, v.y-w.y, v.z-w.z)      # vec subtraction
Base.:*(v::Vec3, w::Vec3) = v.x*w.x + v.y*w.y + v.z*w.z          # vec dot product
Base.:*(s::Real, v::Vec3) = Vec3(s*v.x, s*v.y, s*v.z)            # vec scaling
Base.:*(v::Vec3, s::Real) = s*v                                  # vec scaling
Base.:/(v::Vec3, s::Real) = v*(1/s)                              # vec scaling
×(v::Vec3, w::Vec3) = Vec3(v.y*w.z-v.z*w.y, v.z*w.x-v.x*w.z, v.x*w.y-v.y*w.x)   # cross product
# editor remark: vim in insert mode → Strg+k * X → ×, Strg+k * <letter> → greek letter, Strg+k R T → √
norm(v::Vec3) = √(v*v)                                           # length of vector
normal(v::Vec3) = v/norm(v)                                      # create normal vector

distance(v::Vec3, w::Vec3) = norm(v-w)                           # distance of vectors if considered as 3D points
perpendicular(v::Vec3, w::Vec3) = v - w*((v*w)/norm(w))          # vector through v perpendicular on w

# for generalization later
abstract type Shape end

# concrete type
struct Sphere <: Shape 
  position::Vec3
  radius
  color::Color
  reflectivity
end

# c'tors
Sphere( ;
        position      = Vec3(0.0, 0.0, 0.0),
        radius        = 1.0,
        color::Color  = RGB(1.0,1.0,1.0),
        reflectivity  = 0.2
      ) = Sphere(position, radius, color, reflectivity)
Sphere( ;
        position      = Vec3(0.0, 0.0, 0.0),
        radius        = 1.0,
        color::Symbol = :white,
        reflectivity  = 0.2
      ) = Sphere(position, radius, parse(Colorant, color), reflectivity)
# -------------- geometry objects ----------------------

# -------------- light source ----------------------
struct LightSource
  direction::Vec3
  color::Color
end

# c'tors
LightSource(; direction = Vec3(1.0, 1.0, -1.0), color::Symbol = :white) = LightSource(normal(direction), parse(Colorant, color))
LightSource(; direction = Vec3(1.0, 1.0, -1.0), color::Color = RGB(1.0,1.0,1.0)) = LightSource(normal(direction), color)
# -------------- light source ----------------------

# -------------- camera ----------------------
struct Camera
  position::Vec3
  view_direction::Vec3
  view_port_width::Unsigned
  view_port_height::Unsigned
  angle_resolution::Real
end

# c'tors
Camera(; 
       position         = Vec3(0.0,0.0,0.0), 
       view_direction   = Vec3(1.0,0.0,0.0),
       view_port_width  = 1280,
       view_port_height = 900,
       angle_resolution = 0.0008
      ) = Camera(position,view_direction,view_port_width,view_port_height,angle_resolution)
# -------------- camera ----------------------

# -------------- Rays ----------------------
mutable struct Ray
  origin::Vec3
  direction::Vec3
  color::Color
end

# c'tors
Ray(;
    origin = Vec3(0.0,0.0,0.0),
    direction = Vec3(1.0,0.0,0.0),
    color = RGB(0.0, 0.0, 0.0)
   ) = Ray(origin, normal(direction), color)
# -------------- Rays ----------------------

# ----------------- Sphere Geometry Supplier ------------------
hit(r::Ray, s::Sphere) = norm((s.position-r.origin) × r.direction) < s.radius

function intersect(r::Ray, s::Sphere)
  a = s.position - r.origin
  p = (r.direction * a)
  q = (a*a-s.radius^2)
  p^2 - q < 0 && error("Error: Tried to get point on Sphere not hit by ray!")
  t = p-√(p^2-q)
  return t, r.origin + t * r.direction
end

get_normal(s::Sphere, p::Vec3) = normal(p - s.position)
# ----------------- Sphere Geometry Supplier ------------------
# would need to be defined for any other shape, too

# convenience
Gaus(x) = exp(-0.5*x^2)

# generic handling of shapes for raytracing
# ----------------- Rendering ------------------
function find_closest_object(r::Ray, shapes)
  shape = nothing
  hit_point = nothing
  distance = Inf
  for s in shapes
    if hit(r, s)
      cd, p = intersect(r, s)
      if 0 < cd < distance
        distance = cd
        shape = s
        hit_point = p
      end
    end
  end
  return shape, hit_point
end

# maximum iterative Ray spawning
const MAX_DEPTH = 5

# ray following and ray color update
function render_ray(r::Ray, shapes, depth, lightsource)

  color = RGB(0.0, 0.0, 0.0)           # start with black

  if depth <= MAX_DEPTH

    hit_shape, hit_point = find_closest_object(r, shapes)

    if hit_shape != nothing

      hit_normal = get_normal(hit_shape, hit_point)                    # get normal on hit point (valid for spheres only)
      cosf = -(hit_normal*lightsource.direction)                       # cos(normal,light direction)
      cosd = -(hit_normal*r.direction)                                 # cos(normal,incoming ray)

      ray2light = Ray(origin = hit_point, direction = -1.0*lightsource.direction)                             # ray from hit point to light source

      shadow_shape, shadow_hit_point = find_closest_object(ray2light, filter(x -> x !== hit_shape, shapes))   # check whether shadowing objects are there

      directed_distance = 0.0                                                                                 # signed distance
      if shadow_shape != nothing
        cd, p = intersect(ray2light, shadow_shape)
        directed_distance = (p - ray2light.origin)*ray2light.direction
      end

      # start color determination
      if cosf>0.0 && ( shadow_shape == nothing || directed_distance < 0.0)                                    # insert shadows
        color = clamp01(hit_shape.color*cosf)
      end

      color = clamp01(color * (1.0 - hit_shape.reflectivity))                                                 # insert reflectivity

      # follow reflected ray recursively
      reflect_ray = render_ray(Ray(origin = hit_point, direction = hit_normal*(2.0*cosd) + r.direction), shapes, depth+1, lightsource)
      color = clamp01(color + reflect_ray.color*hit_shape.reflectivity)                                       # combine color with reflected color

      # add headlights
      if cosf>0.0 && ( shadow_shape == nothing || directed_distance < 0.0)
        cosrf = -(reflect_ray.direction*lightsource.direction)
        reflc = hit_shape.reflectivity
        color = clamp01(color + lightsource.color * (Gaus((cosrf-1.0)/(0.005*(1.0-reflc)))*(5.0*reflc)))
      end

      r.color = color
    end
  end

  return r
end

# here runs the for loop over each image pixel
function render_image(camera, shapes, lightsource)
  dimX = camera.view_port_width
  dimY = camera.view_port_height
  focalVec = normal(camera.view_direction)
  vy = normal(Vec3(0.0, 1.0, 0.0))
  vz = focalVec × vy
  res = camera.angle_resolution

  pixel_matrix = zeros(RGB{N0f8}, dimY, dimX)
  for x in 1:camera.view_port_width, y in 1:camera.view_port_height
    gradient = min(1.0, y/camera.view_port_height)
    pixel_matrix[y,x] = RGB(gradient, gradient, min(0.5(1+gradient),1.0))  # color gradient background
    ray = render_ray(Ray(origin = camera.position, direction = focalVec + vy*(res*(0.5*dimX-x)) + vz*(res*(0.5*dimY-y)), color = pixel_matrix[y,x]), 
                     shapes, 
                     0,
                     lightsource)
    pixel_matrix[y,x] = ray.color
  end
  return pixel_matrix   
end 
# ----------------- Rendering ------------------

# -------------- Scene Setup and Rendering --------------------
to_tuple(c::RGB) = (round(Int, red(c)*255), round(Int, green(c)*255), round(Int, blue(c)*255))
Colors.color_names["darkbeige"] = to_tuple(RGB(0.784, 0.784, 0.608))

shapes = Shape[]
push!(shapes, Sphere(position = Vec3( 7.0, -1.0, -1.0), radius = 1.0, color = :green1,     reflectivity = 0.05))
push!(shapes, Sphere(position = Vec3(10.0,  0.0,  0.0), radius = 3.0, color = :red1                           ))
push!(shapes, Sphere(position = Vec3( 5.0,  1.0,  1.0), radius = 1.0, color = :blue1,      reflectivity = 0.6 ))
push!(shapes, Sphere(position = Vec3( 7.5, -2.7,  2.0), radius = 0.7, color = :darkbeige                      ))
push!(shapes, Sphere(position = Vec3( 8.5, -3.5,  0.0), radius = 1.5, color = :magenta                        ))
# ground
push!(shapes, Sphere(position = Vec3( 0.0,  0.0, -1.0e6), radius = 1.0e6 - 4.0, color = :white, reflectivity = 0.001 ))

camera = Camera(position = Vec3(-1.5, 0.0, 0.0))

# Render Image
image = render_image(camera, shapes, LightSource())
save("render_result.png", image)
# -------------- Scene Setup and Rendering --------------------
```
</details>

This program is admittedly already a bit more complex. It is supposed to be extended with shapes other then only spheres. Or, material properties can be extended - though the solution for the following path-tracing is imho more appealing.

It requires the modules `Colors` and `Images` to be installed. And then, it can be executed via `julia raytrace.jl`. A PNG file with the result is produced (if everything works well).
And the serial program may run in about 30 seconds. You can change the view port resolution (and reduce the angle resolution accordingly) if you want more workload.

Finding the main loop is certainly not that hard. Parallelize it with threads or with workers (or otherwise). Check the scaling! (Does parallelism accelerate?)

<details>
  <summary>Plot-Result</summary>

<div align="center">
  <img src="../../miscellanea/images/render_result.png" width="800" alt="ray tracing result">
</div>
</details>

## Path-Tracing

```julia
```
