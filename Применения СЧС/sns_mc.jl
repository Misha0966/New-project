# sns-MC: Структурная Числовая Симметрия + Монте-Карло
# все права защищены
# Автор:  Ющенко Михаил Юрьевич
# Запуск: нажмите ▶️ в VS Code
using Random
using DataFrames
using CSV
using Plots
using ProgressMeter
using FFMPEG # Подключаем все необходимые библиотеки

# Базовые функции СЧС
function split_number_str(N::AbstractString, m::Int)::Vector{String} # Функция для разбиения строки числа на m частей
len = length(N) # Вычисляем общую длину строки
base_len = len ÷ m # Вычисляем базовую длину каждой части
rem = len % m # Вычисляем остаток для распределения лишних символов
parts = String[] # Инициализируем пустой массив для хранения частей
idx = 1 # Задаем начальный индекс для среза
   for i in 1:m # Запускаем цикл по количеству требуемых частей
current_len = base_len + (i <= rem ? 1 : 0) # Считаем текущую длину с учетом остатка
push!(parts, N[idx:idx+current_len-1]) # Вырезаем подстроку и добавляем в массив
idx += current_len # Сдвигаем индекс на длину текущей части
    end
return parts # Возвращаем готовый массив строк-частей
end

function apply_scs(N::BigInt, m::Int, k::Int)::String # Функция применения оператора СЧС к числу
s = string(N) # Переводим большое число в строку
parts = split_number_str(s, m) # Разбиваем строку на m частей
multiplied = [string(parse(BigInt, p) * k) for p in parts] # Парсим каждую часть, умножаем на k и переводим в строку
return join(multiplied) # Склеиваем обработанные части обратно в единую строку
end

function classify_sns(pq::String, nk::String)::Tuple{Int, String} # Функция классификации степени симметрии
    if pq == nk # Проверяем на полное совпадение строк
return (0, "full") # Возвращаем код 0 и статус "full"
elseif length(pq) >= length(nk) && pq[end-length(nk)+1:end] == nk # Проверяем совпадение только в конце
return (2, "end_only") # Возвращаем код 2 и статус "end_only"
elseif startswith(pq, nk[1:min(3, length(nk))]) && endswith(pq, nk[end-min(2, length(nk))+1:end]) # Проверяем совпадение начал и концов
return (1, "both_ends") # Возвращаем код 1 и статус "both_ends"
else
return (3, "none") # Если ничего не совпало, возвращаем код 3 и статус "none"
    end
end

# Генерация данных:
function run_sns_mc_pi_with_data(total_samples::Int = 100_000; m=2, k=7, scale_factor=BigInt(10)^12, seed=12345) # Главная функция симуляции Монте-Карло
Random.seed!(seed) # Фиксируем зерно генератора случайных чисел для воспроизводимости
inside_classic = inside_sns = valid_sns = 0 # Инициализируем счетчики попаданий нулями
raw_data = DataFrame( # Создаем пустой DataFrame для сбора сырых данных
iter = Int[],
x = Float64[],
y = Float64[],
x_inside = Bool[],
sns_valid = Bool[],
sns_type = String[],
π_classic = Float64[],
π_sns = Float64[]
)
prog = ProgressMeter.Progress(total_samples, desc="🎲 Генерация данных...") # Создаем объект прогресс-бара
    for i in 1:total_samples # Запускаем основной цикл симуляции
x, y = rand(), rand() # Генерируем случайные координаты точки
x_inside = (x^2 + y^2 <= 1.0) # Проверяем, попала ли точка в четверть круга (классический метод)
inside_classic += x_inside # Увеличиваем счетчик классических попаданий
X = BigInt(round(x * scale_factor)) # Масштабируем координату X в большое целое число
Y = BigInt(round(y * scale_factor)) # Масштабируем координату Y в большое целое число
N = X * scale_factor + Y # Объединяем X и Y в одно составное число N
pq = apply_scs(N, m, k) # Применяем к числу N оператор СЧС
nk = string(N * k) # Вычисляем контрольное значение (просто N умноженное на k)
flag, sns_type = classify_sns(pq, nk) # Классифицируем полученную симметрию
sns_valid = (flag != 3) # Определяем валидность (true, если статус не "none")
        if sns_valid # Если симметрия признана валидной
valid_sns += 1 # Увеличиваем счетчик валидных точек
inside_sns += x_inside # Учитываем попадание в круг для SNS-метода
        end
π_c = 4.0 * inside_classic / i # Вычисляем текущее классическое приближение Пи
π_s = valid_sns > 0 ? 4.0 * inside_sns / valid_sns : NaN # Вычисляем текущее SNS приближение Пи
push!(raw_data, (i, x, y, x_inside, sns_valid, sns_type, π_c, π_s)) # Добавляем строку с результатами в DataFrame
ProgressMeter.next!(prog) # Обновляем прогресс-бар на одну итерацию
    end
π_classic = 4.0 * inside_classic / total_samples # Вычисляем финальное классическое значение Пи
π_sns = valid_sns > 0 ? 4.0 * inside_sns / valid_sns : NaN # Вычисляем финальное SNS значение Пи
summary = ( # Формируем именованный кортеж с итоговой статистикой
total_samples = total_samples,
valid_sns = valid_sns,
π_classic = π_classic,
π_sns = π_sns,
error_classic = abs(π_classic - π),
error_sns = abs(π_sns - π),
sns_stats = combine(groupby(raw_data[raw_data.sns_valid, :], :sns_type), nrow => :count) # Группируем валидные точки по типам симметрии
)
CSV.write("sns_mc_raw_data.csv", raw_data) # Сохраняем DataFrame с сырыми данными в CSV файл
println("\n💾 Сырые данные сохранены: sns_mc_raw_data.csv") # Выводим уведомление об успешном сохранении
return raw_data, summary # Возвращаем собранные данные и итоговую сводку
end

# Анимация в МР4
function animate_sns_mc(raw_data::DataFrame; fps=20, max_frames=300) # Функция для создания видео-анимации процесса
println("\n🎥 Создаём видео (MP4)...") # Выводим уведомление о начале рендеринга
gr() # Устанавливаем графический бэкенд GR для Plots
total = nrow(raw_data) # Получаем общее количество строк (итераций)
step = max(1, total ÷ max_frames) # Вычисляем шаг выборки для ограничения числа кадров
frame_indices = 1:step:total # Формируем массив индексов для создания кадров
anim = @animate for i in frame_indices # Запускаем цикл генерации кадров анимации
df_sub = raw_data[1:i, :] # Берем подвыборку данных от начала до текущего кадра
π_sns_clean = collect(skipmissing(df_sub.π_sns)) # Очищаем значения SNS Пи от пропусков (NaN)
π_sns_val = isempty(π_sns_clean) ? NaN : last(π_sns_clean) # Берем последнее актуальное значение
colors = [ # Формируем массив цветов для каждой точки на графике
            if row.x_inside
row.sns_valid ? :green : :lightblue # Внутри круга: зеленый если валидно, иначе голубой
else
row.sns_valid ? :red : :orange # Вне круга: красный если валидно, иначе оранжевый
            end
    for row in eachrow(df_sub)
]
scatter( # Рисуем точечную диаграмму (scatter plot)
df_sub.x, df_sub.y,
color = colors,
alpha = 0.6,
markersize = 2.5,
label = "",
xlim = (0, 1),
ylim = (0, 1),
aspect_ratio = :equal,
title = "sns-MC: итерация $(i)/$(total)\n" * # Формируем динамический заголовок графика
"π̂_classic = $(round(last(df_sub.π_classic), digits=4)), " *
"π̂_sns = $(isnan(π_sns_val) ? "N/A" : round(π_sns_val, digits=4))",
titlefontsize = 10
)
θ = range(0, π/2, length=100) # Генерируем массив углов для построения дуги
plot!(cos.(θ), sin.(θ), color=:black, linewidth=1.2, label="") # Рисуем черную четверть окружности поверх точек
    end
mp4(anim, "sns_mc_animation.mp4", fps=fps) # Кодируем и сохраняем анимацию в MP4 файл
println("🎬 Видео сохранено: sns_mc_animation.mp4") # Выводим уведомление об успешном сохранении видео
end

# Экспорт итогов в CSV
function export_summary_csv(summary) # Функция для экспорта итоговой сводки в CSV
summary_df = DataFrame( # Создаем пустой DataFrame с жесткой структурой колонок
total_samples = Int[],
valid_sns = Int[],
π_classic = Float64[],
π_sns = Float64[],
error_classic = Float64[],
error_sns = Float64[],
sns_count_full = Int[],
sns_count_both_ends = Int[],
sns_count_end_only = Int[],
sns_count_none = Int[]
)
push!(summary_df, ( # Добавляем первую строку с базовыми метриками и нулями для типов
summary.total_samples,
summary.valid_sns,
summary.π_classic,
summary.π_sns,
summary.error_classic,
summary.error_sns,
0, 0, 0, 0
))
    for row in eachrow(summary.sns_stats) # Цикл по сгруппированной статистике типов симметрии
col_name = Symbol("sns_count_$(row.sns_type)") # Динамически формируем имя целевой колонки
        if col_name in propertynames(summary_df) # Проверяем, существует ли такая колонка в DataFrame
summary_df[1, col_name] = row.count # Записываем количество точек данного типа
        end
    end
CSV.write("sns_mc_summary.csv", summary_df) # Сохраняем итоговый DataFrame в CSV файл
println("📊 Итоговая статистика: sns_mc_summary.csv") # Выводим уведомление об успешном сохранении
end

# Основной запуск
println("🚀 Запуск sns-MC : СЧС + Монте-Карло → Видео + CSV") # Выводим стартовое сообщение в консоль
N_SAMPLES = 10000 # Задаем общее количество итераций симуляции
M_PARAM = 5 # Задаем параметр m (количество частей для разбиения числа)
K_PARAM = 5 # Задаем параметр k (множитель для частей числа)
raw_data, summary = run_sns_mc_pi_with_data(N_SAMPLES; m=M_PARAM, k=K_PARAM, seed=42) # Запускаем функцию генерации данных
animate_sns_mc(raw_data; fps=24, max_frames=400) # Запускаем функцию создания анимации
export_summary_csv(summary) # Запускаем функцию экспорта итоговой сводки
println("\n✅ ВСЁ ГОТОВО!") # Выводим финальное сообщение об успешном завершении
println("  • Классический π: $(round(summary.π_classic, digits=6))") # Выводим вычисленное классическое значение Пи
println("  • sns-MC π:       $(round(summary.π_sns, digits=6))") # Выводим вычисленное SNS значение Пи
println("  • Ошибки: классика = $(round(summary.error_classic, sigdigits=2)), sns = $(round(summary.error_sns, sigdigits=2))") # Выводим абсолютные ошибки
println("  • Валидных точек: $(summary.valid_sns) / $(summary.total_samples)") # Выводим статистику по валидным точкам СЧС
println("\n📁 Созданы файлы:") # Выводим список сгенерированных файлов
println("   • sns_mc_raw_data.csv") # Печатаем имя файла с сырыми данными
println("   • sns_mc_summary.csv") # Печатаем имя файла со сводкой
println("   • sns_mc_animation.mp4") # Печатаем имя файла с анимацией