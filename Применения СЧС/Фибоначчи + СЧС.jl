using CSV
using DataFrames
using Plots
using Printf
using Statistics
using Dates

let
    # ---------- ПАРАМЕТРы ----------
    N_TERMS      = 10000
    M_SNS        = 2
    K_SNS        = 9999999
    VIDEO_FPS    = 50
    PLOT_SIZE    = (1280, 720)

    # ---------- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ СЧС (ОПТИМИЗИРОВАННЫЕ) ----------
    function split_number_str(N::Integer, m::Integer)
        s = string(N)
        if N < 10
            s = lpad(s, m, '0')
        end
        len = length(s)
        base_len = len ÷ m
        remainder = len % m
        parts = Vector{String}()
        sizehint!(parts, m)  # ← оптимизация: резервируем память
        idx = 1
        @inbounds for i in 1:m  # ← оптимизация: отключаем проверки границ
            current_len = base_len + (i ≤ remainder ? 1 : 0)
            push!(parts, s[idx:idx+current_len-1])
            idx += current_len
        end
        return parts
    end

    function multiply_preserve_length(part::String, k::Integer)
        # ← оптимизация: избегаем промежуточной переменной
        return lpad(string(parse(BigInt, part) * k), length(part), '0')
    end

    # ---------- КЛАССИФИКАТОР ПО ВАШЕЙ ТИПОЛОГИИ (ОПТИМИЗИРОВАННЫЙ) ----------
    function classify_sns_4type(N::BigInt, m::Int, k::Int)
        N == 0 && return ("4_none", 0)

        parts = split_number_str(N, m)
        pq_parts = similar(parts)  # ← оптимизация: предварительное выделение
        @inbounds for i in eachindex(parts)
            pq_parts[i] = multiply_preserve_length(parts[i], k)
        end
        pq = join(pq_parts)
        nk = string(N * k)

        # ← УБРАНО выравнивание lpad — оно избыточно и вредно для СЧС!
        # Сравниваем исходные строки — так корректнее и быстрее.

        L1 = length(pq)
        L2 = length(nk)
        minL = min(L1, L2)

        # Длина совпадающего суффикса — без создания подстрок
        suffix_len = 0
        @inbounds for i in 1:minL
            if pq[L1 - i + 1] == nk[L2 - i + 1]
                suffix_len += 1
            else
                break
            end
        end

        # Длина совпадающего префикса — без создания подстрок
        prefix_len = 0
        @inbounds for i in 1:minL
            if pq[i] == nk[i]
                prefix_len += 1
            else
                break
            end
        end

        # === КЛАССИФИКАЦИЯ ПО ВАШИМ ПРАВИЛАМ ===
        if L1 == L2 && suffix_len == L1
            return ("1_full", suffix_len)
        elseif prefix_len ≥ 2 && suffix_len ≥ 2
            return ("2_both_ends", suffix_len)
        elseif suffix_len ≥ 1
            return ("3_suffix_only", suffix_len)
        else
            return ("4_none", suffix_len)
        end
    end

    # ---------- ВСЁ ОСТАЛЬНОЕ БЕЗ ИЗМЕНЕНИЙ ----------
    println("🔢 Генерация последовательности Фибоначчи...")
    fib = BigInt[]
    a = BigInt(0)
    b = BigInt(1)
    push!(fib, a)
    for i in 1:(N_TERMS - 1)
        push!(fib, b)
        next_b = a + b
        a = b
        b = next_b
    end
    fib = fib[2:end]

    println("🌀 Классификация по 4 типам СЧС...")
    types = String[]
    suffixes = Int[]
    sizehint!(types, N_TERMS)      # ← оптимизация
    sizehint!(suffixes, N_TERMS)   # ← оптимизация
    for f in fib
        t, s = classify_sns_4type(f, M_SNS, K_SNS)
        push!(types, t)
        push!(suffixes, s)
    end

    type_to_color = Dict(
        "1_full"        => :green,
        "2_both_ends"   => :blue,
        "3_suffix_only" => :orange,
        "4_none"        => :lightgray
    )
    colors = [get(type_to_color, t, :black) for t in types]

    df = DataFrame(
        index = 1:length(fib),
        fib_value = fib,
        sns_type = types,
        suffix_len = suffixes
    )
    CSV.write("fibonacci_sns_4type_data.csv", df)

    frame_dir = "fibonacci_sns_4type_frames"
    if isdir(frame_dir)
        rm(frame_dir, recursive=true)
    end
    mkdir(frame_dir)

    println("🎥 Генерация видео по 4 типам...")
    for i in 1:length(fib)
        p = scatter(
            1:i, suffixes[1:i],
            color = colors[1:i],
            xlabel = "n",
            ylabel = "Длина совпадающего суффикса",
            title = "СЧС в Фибоначчи — 4 типа совпадений (по Ющенко М.Ю.)",
            size = PLOT_SIZE,
            legend = false,
            marker = (:circle, 4),
            grid = true,
            background_color_inside = :white
        )
        annotate!(0.05, 0.95, text("n = $i", :black, 10))
        savefig(p, joinpath(frame_dir, @sprintf "frame_%06d.png" i))
    end

    video_ok = false
    try
        run(`ffmpeg -y -framerate $VIDEO_FPS -i $(frame_dir)/frame_%06d.png -c:v libx264 -pix_fmt yuv420p fibonacci_sns_4type_animation.mp4`)
        video_ok = true
    catch
    end

    final_plot = scatter(
        1:length(fib), suffixes,
        color = colors,
        xlabel = "Номер числа Фибоначчи (n)",
        ylabel = "Длина совпадающего суффикса",
        title = "4 типа совпадений СЧС в последовательности Фибоначчи",
        size = PLOT_SIZE,
        grid = true,
        marker = (:circle, 3)
    )
    savefig(final_plot, "fibonacci_sns_4type_plot.png")

    type_names = Dict(
        "1_full"        => "1. Полное совпадение",
        "2_both_ends"   => "2. Совпадение начала и конца",
        "3_suffix_only" => "3. Совпадение конца",
        "4_none"        => "4. Нет совпадений"
    )

    type_counts = Dict{String, Int}()
    for t in types
        type_counts[t] = get(type_counts, t, 0) + 1
    end

    stat_lines = [
        "🎯 СЧС-анализ по 4 типам совпадений",
        "📜 Автор: Ющенко Михаил Юрьевич",
        "📅 Дата: $(Dates.today())",
        "💡 Классификация строго по определению СЧС (Ющенко, 2025)",
        "",
        "==================================================",
        "🔢 Всего чисел: $N_TERMS (F₁ … F_$N_TERMS)",
        "📐 m = $M_SNS, k = $K_SNS",
        "----------------------------------------"
    ]

    for key in ["1_full", "2_both_ends", "3_suffix_only", "4_none"]
        name = type_names[key]
        count = get(type_counts, key, 0)
        push!(stat_lines, "$name: $count")
    end

    push!(stat_lines, "")
    push!(stat_lines, "🎥 Видео: $(video_ok ? "fibonacci_sns_4type_animation.mp4" : "не создано")")
    push!(stat_lines, "🖼️ График: fibonacci_sns_4type_plot.png")
    push!(stat_lines, "📄 Данные: fibonacci_sns_4type_data.csv")

    write("fibonacci_sns_4type_statistics.txt", join(stat_lines, "\n"))

    println("\n✅ Анализ завершён строго по вашей типологии СЧС.")
    println("📁 Все файлы сохранены в требуемых форматах.")
end