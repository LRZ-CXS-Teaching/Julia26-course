# TO RUN THIS FILE, open a julia shell and run the following:
# - for a pure-CPU vs KernelAbstractions-CPU comparison:
#      FORCE_CPU_BACKEND=true; include("2D-heat-equation_benchmarking.jl")      # first run
# - for a CPU vs GPU:
#      FORCE_CPU_BACKEND=false; include("2D-heat-equation_benchmarking.jl")     # first run
#
# Once included for the first time, you can run differen banchmarks (with same backend):
#       T_init = zeros(Float32,256,256);
#       T_init[128,128] = 1.0f0;
#       main_visualization(T_init; N=128, alpha=0.15f0, size=(480, 480), frames=128, steps_per_frame=8, fps=8, out="heat_diffusion.gif")
using Plots

# Backend.jl reads the var FORCE_CPU_BACKEND
#     - if not set (or if set to 0, false, or 'false'), uses the first available GPU backend it finds, i.e:
#         oneAPI, NVidia, AMDCPU, Metal
#     - if set to 1, true, or 'true', uses the KernelAbstractions.CPU() backend
include("../../KernelAbstractions/Backend.jl")


@kernel function heat_step_kernel!(T2, @Const(T1), alpha)
    i, j = @index(Global, NTuple)
    Nx, Ny = size(T1)

    if i > 1 && i < Nx && j > 1 && j < Ny
        @inbounds T2[i, j] = T1[i, j] + alpha * (T1[i+1, j] + T1[i-1, j] + T1[i, j+1] + T1[i, j-1] - 4 * T1[i, j])
    end
end

function evolve_heat!(T1, T2, alpha, n_steps; workgroupsize=(16, 16))
    backend = get_backend(T1)
    kernel! = heat_step_kernel!(backend, workgroupsize)
    ndrange = size(T1)

    active, buffer = T1, T2
    for _ in 1:n_steps
        kernel!(buffer, active, alpha, ndrange=ndrange)
        KernelAbstractions.synchronize(backend)
        active, buffer = buffer, active
    end
    return active
end

function main_visualization(T1=nothing; N=128, alpha=0.15f0, size=(480, 480), frames=128, steps_per_frame=8, fps=8, out="heat_diffusion.gif")
    if isnothing(T1)
        T_host = zeros(Float32, N, N)
        center, radius = N ÷ 2, N ÷ 10
        T_host[center-radius:center+radius, center-radius:center+radius] .= 200.0f0
    else
        T_host = T1
    end

    T1, T2 = DevArray(T_host), DevArray(T_host)

    active = T1
    buffer = T2

    anim = @animate for frame in 1:frames
        # Evolve strictly on device
        active = evolve_heat!(active, buffer, alpha, steps_per_frame)
        buffer = (active === T1) ? T2 : T1

        # Mandatory PCIe transfer for Plots.jl
        host_frame = Array(active)

        heatmap(host_frame, c=:inferno, clims=(0, 100),
            title="Heat Diffusion - Step $(frame * steps_per_frame)",
            aspect_ratio=:equal, legend=false, framestyle=:box, size=size)
    end

    # ffmpeg options:
    # -f image2 : select type "image file demuxer"
    #     * reads from a list of image files specified by a pattern
    #     * the syntax and meaning of the pattern is specified by the option pattern_type
    #     * size, pixel format, and the format of each image must be the same for all the files in the sequence
    # -framerate : set the frame rate for the video stream (default: 25)
    # -loop {0|1} : if set to 1, loop over the input (default: 0)
    # -s $(width)x$(height) 
    # -vcodec codec (output) : set the video codec (alias for "-codec:v")
    #     * video encoders can take input in either of nv12 or yuv420p form
    #     * very common to use libx264 (and libx264rgb)
    #         * x264 H.264/MPEG-4 AVC encoder wrapper
    #         * libx264 supports an impressive number of features
    #         * libx264rgb encoder is the same as libx264, except it accepts packed RGB pixel formats as input instead of YUV
    # -pix-fmt (aka -pixel_format): set the input video pixel format (default: "yuv420p")
    #
    # very common choice: -vcodec libx264 -pix_fmt yuv420p
    # we will use:        -vcodec gif -pix_fmt rgb8
    run(`ffmpeg -f image2 -framerate $(fps) -loop 0 -start_number 1 -s $(size[1])x$(size[2]) -i $(anim.dir)/%06d.png -vcodec gif -pix_fmt rgb8 ./$(out)`)
    #gif(anim, "$out", fps=fps)     # recommended, but sometimes broken
end

main_visualization()
