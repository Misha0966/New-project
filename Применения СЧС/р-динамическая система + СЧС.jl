# ------------------------------------------------------------
# Structural Numerical Symmetry (SNS) in p-adic system
# Code in English; output (TXT, CSV, video labels) in Russian
# ------------------------------------------------------------

using Printf
using CSV
using DataFrames
using Plots
using ProgressMeter
using Base.Threads

gr()

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

function base_p_string(N::Integer, p::Integer, L::Integer)
    N_mod = N % (p^L)
    digits_p = digits(N_mod, base = p, pad = L)
    return join(reverse(digits_p))
end

function split_string_equal(s::String, m::Integer)
    len = length(s)
    base_len = div(len, m)
    remainder = len % m
    parts = String[]
    idx = 1
    for i in 1:m
        current_len = base_len + (i <= remainder ? 1 : 0)
        push!(parts, s[idx:idx+current_len-1])
        idx += current_len
    end
    return parts
end

function multiply_preserve_length_p(part::String, k::Integer, p::Integer)
    if all(c == '0' for c in part)
        num = 0
    else
        num = parse(BigInt, part, base = p)
    end
    prod = (num * k) % (p^length(part))
    res_str = string(prod, base = p)
    return lpad(res_str, length(part), '0')
end

function remove_leading_zeros_p(s::String)
    if all(c == '0' for c in s)
        return "0"
    else
        idx = findfirst(c -> c != '0', s)
        return s[idx:end]
    end
end

function compare_pq_nk(pq::String, nk::String)
    if pq == nk
        return "ПОЛНОЕ СОВПАДЕНИЕ"
    end
    min_len = min(length(pq), length(nk))
    prefix = 0
    for i in 1:min_len
        pq[i] == nk[i] ? prefix += 1 : break
    end
    suffix = 0
    for i in 1:min_len
        pq[end-i+1] == nk[end-i+1] ? suffix += 1 : break
    end
    if prefix > 0 && suffix > 0
        return "СОВПАДАЮТ НАЧАЛО И КОНЕЦ"
    elseif prefix > 0
        return "СОВПАДАЕТ ТОЛЬКО НАЧАЛО"
    elseif suffix > 0
        return "СОВПАДАЕТ ТОЛЬКО КОНЕЦ"
    else
        return "НЕТ СОВПАДЕНИЙ"
    end
end

# ------------------------------------------------------------
# Frame generation — m passed explicitly
# ------------------------------------------------------------

function plot_sns_frame(N, parts, mult_parts, PQ, NK, result, p, L, k, m, frame_dir, frame_id)
    fig = plot(
        title = "СЧС | p = $p | N = $N | k = $k | L = $L",
        size = (1200, 700),
        layout = (4, 1),
        top_margin = 10Plots.mm,
        bottom_margin = 10Plots.mm,
        titlefontsize = 12,
        grid = false
    )

    # 1. N in base-p
    N_str = base_p_string(N, p, L)
    plot!(fig[1], xlims = (0.5, L + 0.5), yticks = ([], []), xticks = (1:L, collect(N_str)),
          seriestype = :scatter, markersize = 0, label = "")
    for i in 1:L
        annotate!(fig[1], (i, 0.5, text(string(N_str[i]), :center, 12)))
    end
    plot!(fig[1], title = "N в $p-ичной записи (длина L = $L)")

    # 2. Split into m parts
    y_pos = 1:length(parts)
    plot!(fig[2], yticks = (y_pos, ["Часть $i" for i in y_pos]), xticks = ([], []),
          seriestype = :scatter, markersize = 0, label = "")
    for (i, part) in enumerate(parts)
        annotate!(fig[2], (0, i, text(part, :center, 12)))
    end
    plot!(fig[2], title = "Разбиение на $m частей")

    # 3. Local multiplication result
    plot!(fig[3], yticks = (1:length(mult_parts), ["×k" for _ in mult_parts]), xticks = ([], []),
          seriestype = :scatter, markersize = 0, label = "")
    for (i, mp) in enumerate(mult_parts)
        annotate!(fig[3], (0, i, text(mp, :center, 12)))
    end
    pq_full = join(mult_parts)
    annotate!(fig[3], (0, 0.3, text("PQ = $pq_full", :center, 11, :red)))
    plot!(fig[3], title = "Результат локального умножения")

    # 4. PQ vs NK
    color_map = Dict(
        "ПОЛНОЕ СОВПАДЕНИЕ"          => :green,
        "СОВПАДАЮТ НАЧАЛО И КОНЕЦ"   => :gold,
        "СОВПАДАЕТ ТОЛЬКО НАЧАЛО"    => :orange,
        "СОВПАДАЕТ ТОЛЬКО КОНЕЦ"     => :coral,
        "НЕТ СОВПАДЕНИЙ"             => :red
    )
    bar_color = get(color_map, result, :black)
    bar!(fig[4], [1, 2], [1.0, 1.0], color = [bar_color, :purple], label = "",
         xticks = ([1, 2], ["PQ", "NK"]))
    annotate!(fig[4], (1, 1.15, text(PQ, :center, 11)))
    annotate!(fig[4], (2, 1.15, text(NK, :center, 11)))
    annotate!(fig[4], (1.5, 0.5, text(result, :center, 12, bar_color)))
    plot!(fig[4], yticks = ([], []), title = "Сравнение: глобальное vs локальное")

    savefig(fig, joinpath(frame_dir, @sprintf "frame_%06d.png" frame_id))
end

# ------------------------------------------------------------
# Main analysis function
# ------------------------------------------------------------

function run_sns_p_adic_video(start_N::Integer, stop_N::Integer, m::Integer, k::Integer, p::Integer, L::Integer)
    mkpath("frames")
    results_df = DataFrame(
        N = Int[],
        m = Int[],
        k = Int[],
        p = Int[],
        L = Int[],
        parts = String[],
        multiplied_parts = String[],
        PQ = String[],
        NK = String[],
        result = String[]
    )

    count_full = Atomic{Int}(0)
    count_both = Atomic{Int}(0)
    count_start = Atomic{Int}(0)
    count_end = Atomic{Int}(0)
    count_none = Atomic{Int}(0)

    total = stop_N - start_N + 1
    @showprogress "Running SNS analysis" for (idx, N) in enumerate(start_N:stop_N)
        N_p = N % (p^L)
        N_str = base_p_string(N_p, p, L)

        parts = split_string_equal(N_str, m)
        mult_parts = [multiply_preserve_length_p(part, k, p) for part in parts]

        PQ_raw = join(mult_parts)
        NK_raw = string((N_p * k) % (p^L), base = p)

        PQ = remove_leading_zeros_p(PQ_raw)
        NK = remove_leading_zeros_p(NK_raw)

        result = compare_pq_nk(PQ, NK)

        if result == "ПОЛНОЕ СОВПАДЕНИЕ"
            Threads.atomic_add!(count_full, 1)
        elseif result == "СОВПАДАЮТ НАЧАЛО И КОНЕЦ"
            Threads.atomic_add!(count_both, 1)
        elseif result == "СОВПАДАЕТ ТОЛЬКО НАЧАЛО"
            Threads.atomic_add!(count_start, 1)
        elseif result == "СОВПАДАЕТ ТОЛЬКО КОНЕЦ"
            Threads.atomic_add!(count_end, 1)
        else
            Threads.atomic_add!(count_none, 1)
        end

        push!(results_df, (
            N = N,
            m = m,
            k = k,
            p = p,
            L = L,
            parts = string(parts),
            multiplied_parts = string(mult_parts),
            PQ = PQ,
            NK = NK,
            result = result
        ))

        if total <= 5000
            plot_sns_frame(N, parts, mult_parts, PQ, NK, result, p, L, k, m, "frames", idx)
        end
    end

    CSV.write("results_sns_p_adic.csv", results_df)

    full = count_full[]
    both = count_both[]
    start = count_start[]
    ennd = count_end[]
    none = count_none[]

    open("statistics_sns_p_adic.txt", "w") do io
        write(io, "Структурная Числовая Симметрия (СЧС) — p-адическая система\n")
        write(io, "==========================================================\n")
        write(io, "Диапазон N: [$start_N, $stop_N]\n")
        write(io, "Основание p = $p, длина L = $L\n")
        write(io, "Количество частей m = $m, множитель k = $k\n")
        write(io, "----------------------------------------------------------\n")
        write(io, "ПОЛНОЕ СОВПАДЕНИЕ         : $full\n")
        write(io, "СОВПАДАЮТ НАЧАЛО И КОНЕЦ  : $both\n")
        write(io, "СОВПАДАЕТ ТОЛЬКО НАЧАЛО   : $start\n")
        write(io, "СОВПАДАЕТ ТОЛЬКО КОНЕЦ    : $ennd\n")
        write(io, "НЕТ СОВПАДЕНИЙ            : $none\n")
        write(io, "Данные → 'results_sns_p_adic.csv'\n")
    end

    println("\n✓ Statistics saved to 'statistics_sns_p_adic.txt'")
    println("✓ Results saved to 'results_sns_p_adic.csv'")

    if total <= 5000
        video_name = "sns_p$(p)_m$(m)_k$(k)_N$(start_N)-$(stop_N).mp4"
        println("\n🎥 Building video...")
        try
            run(pipeline(`ffmpeg -y -framerate 15 -i frames/frame_%06d.png -c:v libx264 -pix_fmt yuv420p $video_name`, stderr = devnull))
            println("✓ Video saved: $video_name")
        catch e
            println("⚠️  Video creation failed. Ensure ffmpeg is installed.")
        end
    else
        println("\nℹ️  Range too large for video (N span > 5000).")
    end

    return results_df
end

# ------------------------------------------------------------
# Parameters — in English
# ------------------------------------------------------------

const START_N = 1
const STOP_N  = 10000000
const M       = 2
const K       = 3
const P       = 7
const L       = 12

# Run
run_sns_p_adic_video(START_N, STOP_N, M, K, P, L)