using Printf
using CSV
using DataFrames

# Проверяет, является ли число n простым.
function is_prime(n::Integer)::Bool
    n < 2 && return false
    n == 2 && return true
    iseven(n) && return false
    for i in 3:isqrt(n)+1
        n % i == 0 && return false
    end
    return true
end

# Генерирует список всех простых чисел в диапазоне [start, stop].
function generate_primes(start::Integer, stop::Integer)::Vector{Int}
    primes = Int[]
    for n in max(2, start):stop
        if is_prime(n)
            push!(primes, n)
        end
    end
    return primes
end

# Разбивает число N на m частей равной длины.
# Если длина N не делится на m, части будут максимально близкими по длине.
function split_number(N::Integer, m::Integer)::Vector{Int}
    s = string(N)
    d = length(s)

    if m <= 0
        error("Число частей должно быть положительным")
    end

    l = div(d, m)
    rem = d % m

    parts = Int[]
    idx = 1

    for i in 1:m
        current_length = l + (i <= rem ? 1 : 0)
        part = parse(Int, s[idx:idx+current_length-1])
        push!(parts, part)
        idx += current_length
    end

    return parts
end

# Определяет тип совпадения между PQ и N*k.
# Теперь возвращает универсальные категории для статистики.
function classify_match(pq::Integer, product::Integer)::String
    pq_str = string(pq)
    prod_str = string(product)

    # Полное совпадение
    if pq == product
        return "✅ Полное совпадение"
    end

    # Масштабированное совпадение (в 10^n раз)
    for n in 1:5
        if pq == product * 10^n
            return "🔄 Совпадение в $n раз(а)"
        end
    end

    # Совпадает начало?
    min_len = min(length(pq_str), length(prod_str))
    for i in 1:min_len
        if pq_str[1:i] != prod_str[1:i]
            break
        end
        if i == min_len || prod_str[i+1] != pq_str[i+1]
            return "🔄 Совпадают начальные цифры"
        end
    end

    # Совпадает конец?
    for i in 1:min_len
        pos_pq = length(pq_str) - i + 1
        pos_prod = length(prod_str) - i + 1
        if pq_str[pos_pq:end] == prod_str[pos_prod:end]
            return "🔄 Совпадают последние цифры"
        end
    end

    # Нет совпадений
    return "❌ Нет совпадений"
end

# Проверяет, выполняется ли гипотеза структурной числовой симметрии для числа N.
function check_symmetry(N::Integer, k::Integer, m::Integer)::Tuple{Bool,String}
    s = string(N)
    d = length(s)

    # Если невозможно разбить на m частей хотя бы по одной цифре
    if d < m
        return false, "⚠️ Ошибка: слишком мало цифр для разбиения на $m частей"
    end

    try
        parts = split_number(N, m)
        q_parts = [part * k for part in parts]
        pq = parse(BigInt, join(string.(q_parts)))
        product = N * k

        result = classify_match(pq, product)
        return true, result
    catch e
        return false, "⚠️ Ошибка: $(sprint(showerror, e))"
    end
end

# Запускает проверку гипотезы для всех чисел от start до stop.
function run_check_range(start::Integer, stop::Integer, k::Integer, m::Integer)
    println("🔍 Проверка чисел от $start до $stop, k = $k, m = $m:")
    println("-"^60)

    stats = Dict(
        "✅ Полное совпадение" => 0,
        "🔄 Совпадение в 1 раз" => 0,
        "🔄 Совпадение в 2 раза" => 0,
        "🔄 Совпадение в 3 раза" => 0,
        "🔄 Совпадение в 4 раза" => 0,
        "🔄 Совпадение в 5 раз" => 0,
        "🔄 Совпадают начальные цифры" => 0,
        "🔄 Совпадают последние цифры" => 0,
        "❌ Нет совпадений" => 0,
        "⚠️ Ошибки" => 0
    )

    for N in start:stop
        success, result = check_symmetry(N, k, m)

        if !success
            stats["⚠️ Ошибки"] += 1
            continue
        end

        stats[result] += 1

        if verbose
            @printf "N = %8d → %s\n" N result
        end
    end

    println("\n📊 Статистика совпадений:")
    for (key, value) in sort(collect(stats), by = x -> -x[2])
        println("  $key: $value")
    end
end

# Запускает проверку гипотезы только для **простых чисел** от start до stop.
function run_check_primes(start::Integer, stop::Integer, k::Integer, m::Integer)
    println("🔍 Проверка ПРОСТЫХ чисел от $start до $stop, k = $k, m = $m:")
    println("-"^60)

    primes = generate_primes(start, stop)
    isempty(primes) && return println("🚫 Простых чисел в этом диапазоне нет.")

    stats = Dict(
        "✅ Полное совпадение" => 0,
        "🔄 Совпадение в 1 раз" => 0,
        "🔄 Совпадение в 2 раза" => 0,
        "🔄 Совпадение в 3 раза" => 0,
        "🔄 Совпадение в 4 раза" => 0,
        "🔄 Совпадение в 5 раз" => 0,
        "🔄 Совпадают начальные цифры" => 0,
        "🔄 Совпадают последние цифры" => 0,
        "❌ Нет совпадений" => 0,
        "⚠️ Ошибки" => 0
    )

    for N in primes
        success, result = check_symmetry(N, k, m)

        if !success
            stats["⚠️ Ошибки"] += 1
            continue
        end

        stats[result] += 1
        @printf "N = %8d → %s\n" N result
    end

    println("\n📊 Статистика совпадений (для простых чисел):")
    for (key, value) in sort(collect(stats), by = x -> -x[2])
        println("  $key: $value")
    end
end

# Запускает проверку гипотезы для всех чисел от start до stop.
# Сохраняет результаты в CSV-файл.
function run_check_range_to_file(start::Integer, stop::Integer, k::Integer, m::Integer, filename::String = "results.csv", verbose::Bool = true)
    if verbose
        println("🔍 Проверка чисел от $start до $stop, k = $k, m = $m:")
        println("-"^60)
    end

    stats = Dict(
        "✅ Полное совпадение" => 0,
        "🔄 Совпадение в 1 раз" => 0,
        "🔄 Совпадение в 2 раза" => 0,
        "🔄 Совпадение в 3 раза" => 0,
        "🔄 Совпадение в 4 раза" => 0,
        "🔄 Совпадение в 5 раз" => 0,
        "🔄 Совпадают начальные цифры" => 0,
        "🔄 Совпадают последние цифры" => 0,
        "❌ Нет совпадений" => 0,
        "⚠️ Ошибки" => 0
    )

    df = DataFrame(N=Int[], k=Int[], m=Int[], PQ=String[], product=String[], result=String[])

    for N in start:stop
        s = string(N)
        d = length(s)

        # Пропускаем числа, которые нельзя разбить на m частей
        if d < m
            error_msg = "⚠️ Ошибка: слишком мало цифр для разбиения на $m частей"
            push!(df, [N, k, m, "", "", error_msg])
            stats["⚠️ Ошибки"] += 1
            continue
        end

        success, result = check_symmetry(N, k, m)

        if !success
            stats["⚠️ Ошибки"] += 1
            push!(df, [N, k, m, "", "", result])
            continue
        end

        parts = split_number(N, m)
        q_parts = [part * k for part in parts]
        pq = join(string.(q_parts))
        product = string(N * k)

        push!(df, [N, k, m, pq, product, result])

        stats[result] += 1

        if verbose
            @printf "N = %8d → %s\n" N result
        end
    end

    # Сохраняем в CSV
    CSV.write(filename, df)

    if verbose
        println("\n💾 Результаты сохранены в файл: $filename")
        println("\n📊 Статистика совпадений:")
        for (key, value) in sort(collect(stats), by = x -> -x[2])
            println("  $key: $value")
        end
    end
end

# 🔁 Запуск примера
start = 10
stop =  100
k = 7
m = 2

run_check_range_to_file(start, stop, k, m, "results.csv", true)