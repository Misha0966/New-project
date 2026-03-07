using CSV  # подключаем модуль для работы с csv
using DataFrames  # подключаем модуль для табличных данных
using Plots  # подключаем модуль для построения графиков
using Printf  # подключаем модуль для форматированного вывода
using Statistics  # подключаем модуль для статистических функций
using Dates  # подключаем модуль для работы с датами

let
# параметры анализа
N_TERMS      = 10000  # количество чисел фибоначчи для анализа
M_SNS        = 2  # количество частей при разбиении числа в счс
K_SNS        = 9999999  # множитель k в преобразовании счс
VIDEO_FPS    = 50  # частота кадров видео
PLOT_SIZE    = (1280, 720)  # размер изображения графика

# разбивает число на m частей как строки, дополняя нулями при необходимости
function split_number_str(N::Integer, m::Integer)
s = string(N)  # преобразуем число в строку
if N < 10  # если число меньше 10, добавляем ведущие нули до длины m
s = lpad(s, m, '0')  # выравниваем слева нулями
end
len = length(s)  # общая длина строки
base_len = len ÷ m  # базовая длина каждой части
remainder = len % m  # остаток от деления
parts = Vector{String}()  # создаём пустой вектор для частей
sizehint!(parts, m)  # резервируем память под m элементов
idx = 1  # начальный индекс
@inbounds for i in 1:m  # проходим по каждой части без проверки границ
current_len = base_len + (i ≤ remainder ? 1 : 0)  # текущая длина части
push!(parts, s[idx:idx+current_len-1])  # извлекаем подстроку и добавляем
idx += current_len  # сдвигаем индекс
end
return parts  # возвращаем список частей
end

# умножает часть числа на k и сохраняет исходную длину, дополняя нулями слева
function multiply_preserve_length(part::String, k::Integer)
return lpad(string(parse(BigInt, part) * k), length(part), '0')  # умножение и выравнивание
end

# классифицирует совпадения по четырём типам согласно моей типологии счс
function classify_sns_4type(N::BigInt, m::Int, k::Int)
N == 0 && return ("4_none", 0)  # ноль не имеет совпадений

parts = split_number_str(N, m)  # разбиваем число на части
pq_parts = similar(parts)  # создаём массив той же структуры
@inbounds for i in eachindex(parts)  # обрабатываем каждую часть
pq_parts[i] = multiply_preserve_length(parts[i], k)  # умножаем с сохранением длины
end
pq = join(pq_parts)  # собираем результат в строку
nk = string(N * k)  # реальное произведение как строка

L1 = length(pq)  # длина счс-результата
L2 = length(nk)  # длина истинного произведения
minL = min(L1, L2)  # минимальная длина для сравнения

suffix_len = 0  # длина совпадающего суффикса
@inbounds for i in 1:minL  # сравниваем с конца
if pq[L1 - i + 1] == nk[L2 - i + 1]  # если символы совпадают
suffix_len += 1  # увеличиваем счётчик
else
break  # иначе прерываем цикл
end
end

prefix_len = 0  # длина совпадающего префикса
@inbounds for i in 1:minL  # сравниваем с начала
if pq[i] == nk[i]  # если символы совпадают
prefix_len += 1  # увеличиваем счётчик
else
break  # иначе прерываем цикл
end
end

if L1 == L2 && suffix_len == L1  # полное совпадение
return ("1_full", suffix_len)
elseif prefix_len ≥ 2 && suffix_len ≥ 2  # совпадение начала и конца
return ("2_both_ends", suffix_len)
elseif suffix_len ≥ 1  # только конец совпадает
return ("3_suffix_only", suffix_len)
else  # нет совпадений
return ("4_none", suffix_len)
end
end

println("генерация последовательности фибоначчи...")  # информационное сообщение
fib = BigInt[]  # инициализируем пустой массив для чисел фибоначчи
a = BigInt(0)  # первое число последовательности
b = BigInt(1)  # второе число последовательности
push!(fib, a)  # добавляем нулевой элемент
for i in 1:(N_TERMS - 1)  # генерируем оставшиеся числа
push!(fib, b)  # добавляем текущее число
next_b = a + b  # вычисляем следующее число
a = b  # сдвигаем a на место b
b = next_b  # обновляем b
end
fib = fib[2:end]  # удаляем нулевой элемент, оставляя f₁ и далее

println("классификация по 4 типам счс...")  # информационное сообщение
types = String[]  # массив для хранения типов совпадений
suffixes = Int[]  # массив для хранения длин суффиксов
sizehint!(types, N_TERMS)  # резервируем память под типы
sizehint!(suffixes, N_TERMS)  # резервируем память под длины
for f in fib  # перебираем все числа фибоначчи
t, s = classify_sns_4type(f, M_SNS, K_SNS)  # классифицируем текущее число
push!(types, t)  # сохраняем тип
push!(suffixes, s)  # сохраняем длину суффикса
end

type_to_color = Dict(  # сопоставление типов цветам для графика
"1_full"        => :green,
"2_both_ends"   => :blue,
"3_suffix_only" => :orange,
"4_none"        => :lightgray
)
colors = [get(type_to_color, t, :black) for t in types]  # получаем цвета по типам

df = DataFrame(  # создаём таблицу данных
index = 1:length(fib),  # индексы чисел
fib_value = fib,  # сами числа фибоначчи
sns_type = types,  # типы счс
suffix_len = suffixes  # длины совпадающих суффиксов
)
CSV.write("fibonacci_sns_4type_data.csv", df)  # сохраняем таблицу в csv файл

frame_dir = "fibonacci_sns_4type_frames"  # имя папки для кадров
if isdir(frame_dir)  # если папка уже существует
rm(frame_dir, recursive=true)  # удаляем её со всем содержимым
end
mkdir(frame_dir)  # создаём новую папку для кадров

println("генерация видео по 4 типам...")  # информационное сообщение
for i in 1:length(fib)  # генерируем кадры по одному
p = scatter(  # строим точечный график
1:i, suffixes[1:i],  # ось x и y
color = colors[1:i],  # цвета точек
xlabel = "n",  # подпись оси x
ylabel = "длина совпадающего суффикса",  # подпись оси y
title = "счс в фибоначчи — 4 типа совпадений (по ющенко м ю)",  # заголовок
size = PLOT_SIZE,  # размер изображения
legend = false,  # отключаем легенду
marker = (:circle, 4),  # форма и размер маркеров
grid = true,  # включаем сетку
background_color_inside = :white  # белый фон внутри графика
)
annotate!(0.05, 0.95, text("n = $i", :black, 10))  # добавляем номер текущего кадра
savefig(p, joinpath(frame_dir, @sprintf "frame_%06d.png" i))  # сохраняем кадр как png
end

video_ok = false  # флаг успешного создания видео
try  # пытаемся запустить ffmpeg
run(`ffmpeg -y -framerate $VIDEO_FPS -i $(frame_dir)/frame_%06d.png -c:v libx264 -pix_fmt yuv420p fibonacci_sns_4type_animation.mp4`)  # команда ffmpeg
video_ok = true  # если успешно, устанавливаем флаг
catch  # если возникла ошибка
end  # игнорируем ошибку

final_plot = scatter(  # строим финальный график всех точек
1:length(fib), suffixes,  # данные по осям
color = colors,  # цвета по типам
xlabel = "номер числа фибоначчи (n)",  # подпись оси x
ylabel = "длина совпадающего суффикса",  # подпись оси y
title = "4 типа совпадений счс в последовательности фибоначчи",  # заголовок
size = PLOT_SIZE,  # размер изображения
grid = true,  # включаем сетку
marker = (:circle, 3)  # форма и размер маркеров
)
savefig(final_plot, "fibonacci_sns_4type_plot.png")  # сохраняем график как png

type_names = Dict(  # человекочитаемые названия типов
"1_full"        => "1. полное совпадение",
"2_both_ends"   => "2. совпадение начала и конца",
"3_suffix_only" => "3. совпадение конца",
"4_none"        => "4. нет совпадений"
)

type_counts = Dict{String, Int}()  # словарь для подсчёта количества по типам
for t in types  # перебираем все типы
type_counts[t] = get(type_counts, t, 0) + 1  # увеличиваем счётчик
end

stat_lines = [  # список строк для текстового отчёта
"анализ счс по 4 типам совпадений",  # заголовок отчёта
"автор: ющенко михаил юрьевич",  # авторство
"дата: $(Dates.today())",  # текущая дата
"классификация строго по определению счс (ющенко, 2025)",  # методология
"",  # пустая строка
"всего чисел: $N_TERMS (f₁ … f_$N_TERMS)",  # количество проанализированных чисел
"m = $M_SNS, k = $K_SNS"  # параметры счс
]

for key in ["1_full", "2_both_ends", "3_suffix_only", "4_none"]  # перебираем типы в заданном порядке
name = type_names[key]  # получаем название типа
count = get(type_counts, key, 0)  # получаем количество или 0
push!(stat_lines, "$name: $count")  # добавляем строку в отчёт
end

push!(stat_lines, "")  # пустая строка перед выводом файлов
push!(stat_lines, "видео: $(video_ok ? "fibonacci_sns_4type_animation.mp4" : "не создано")")  # статус видео
push!(stat_lines, "график: fibonacci_sns_4type_plot.png")  # имя файла графика
push!(stat_lines, "данные: fibonacci_sns_4type_data.csv")  # имя файла данных

write("fibonacci_sns_4type_statistics.txt", join(stat_lines, "\n"))  # записываем отчёт в текстовый файл

println("\nанализ завершён строго по моей типологии счс.")  # финальное сообщение
println("все файлы сохранены в требуемых форматах.")  # подтверждение сохранения
end
