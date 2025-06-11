using Printf # Подключает модуль для форматированного вывода (например, @printf)
using CSV # Подключает библиотеку для работы с CSV-файлами
using DataFrames # Подключает тип данных DataFrame для табличного хранения результатов
using Base.Threads # Включает поддержку многопоточности
using ProgressMeter # Позволяет отображать прогресс выполнения циклов

# Функция разбивает число N на m частей максимально близких по длине
function split_number_str(N::Integer, m::Integer)
s = string(N)  # Преобразует число N в строку

if N < 10 # Если число меньше 10 — дополняем ведущими нулями до длины m
s = lpad(s, m, '0')  # Добавляем слева нули до длины m
end

len = length(s)  # Определяем общую длину строки
base_len = div(len, m)  # Базовая длина части
remainder = len % m  # Остаток при делении — сколько частей будут длиннее на 1 символ

parts = String[]  # Массив для хранения частей числа
idx = 1  # Текущая позиция в строке

for i in 1:m  # Цикл по количеству частей
current_len = base_len + (i <= remainder ? 1 : 0)  # Вычисляем длину текущей части
push!(parts, s[idx:idx+current_len-1])  # Добавляем часть в массив
idx += current_len  # Сдвигаем индекс начала следующей части
end

return parts  # Возвращаем массив частей числа
end

# Умножает часть числа, сохраняя его длину
function multiply_preserve_length(part::String, k::Integer)
num = parse(BigInt, part) * k  # Преобразуем часть в число и умножаем на k
result = string(num)  # Обратно в строку
return lpad(result, length(part), '0')  # Сохраняем исходную длину, добавляя нули слева
end

# Удаляет ведущие нули из строки
function remove_leading_zeros(s::String)
if all(c -> c == '0', s)  # Если вся строка состоит из нулей
return "0"  # Возвращаем "0"
else
idx = findfirst(c -> c != '0', s)  # Находим первый не-нулевой символ
return s[idx:end]  # Возвращаем строку без ведущих нулей
end
end

# Сравнивает PQ и NK по началу и концу
function compare_pq_nk(pq::String, nk::String)
if pq == nk  # Полное совпадение
return "✅ Полное совпадение"
end

min_len = min(length(pq), length(nk))  # Минимальная длина строк
prefix_match = 0  # Счётчик совпадений спереди
for i in 1:min_len  # Цикл сравнения символов с начала
pq[i] == nk[i] ? prefix_match += 1 : break  # Увеличиваем счётчик или выходим
end

suffix_match = 0  # Счётчик совпадений с конца
for i in 1:min_len  # Цикл сравнения символов с конца
pq[end - i + 1] == nk[end - i + 1] ? suffix_match += 1 : break  # Увеличиваем или выходим
end

if prefix_match > 0 && suffix_match > 0  # Совпадают начало и конец
return "🔄 Совпадают начало и конец"
elseif prefix_match > 0  # Только начало
return "🔄 Совпадает только начало"
elseif suffix_match > 0  # Только конец
return "🔄 Совпадает только конец"
else  # Нет совпадений
return "❌ Нет совпадений"
end
end

# Проверка алгоритма для одного числа
function check_algoritm(N::Integer, m::Integer, k::Integer)
N_str = string(N)  # Преобразуем N в строку
nk_str = string(N * k)  # Умножаем N на k и преобразуем в строку

parts_str = split_number_str(N, m)  # Разбиваем N на m частей
multiplied_parts_str = [multiply_preserve_length(p, k) for p in parts_str]  # Умножаем каждую часть
pq_str = join(multiplied_parts_str)  # Объединяем части обратно

# Удаление ведущих нулей перед сравнением
pq_clean = remove_leading_zeros(pq_str)  # Чистим PQ
nk_clean = remove_leading_zeros(nk_str)  # Чистим NK

result = compare_pq_nk(pq_clean, nk_clean)  # Сравниваем PQ и NK

return (  # Возвращаем именованный кортеж (NamedTuple) с результатами проверки СЧС
N = N,  # Исходное число N
m = m,  # Число частей, на которое было разбито N
k = k,  # Множитель, на который умножались части числа
parts = string(parts_str),  # Строковое представление разбиения числа на части
multiplied_parts = string(multiplied_parts_str),  # Строковое представление умноженных частей
PQ = pq_clean,  # Результат конкатенации умноженных частей (очищенный от ведущих нулей)
NK = nk_clean,  # Результат умножения всего числа на k (N * k) (очищенный от ведущих нулей)
result = result  # Результат сравнения строк PQ и NK (полное совпадение, начало, конец и т.д.)
)  # Итоговый NamedTuple содержит все данные по проверке для одного числа N
end

# Параллельная проверка диапазона чисел
function run_tests_parallel(start_N::Integer, stop_N::Integer, m::Integer, k::Integer)
results_df = DataFrame(  # Создаём DataFrame для хранения результатов
N = Int[], # Поле "N" — целые числа
m = Int[], # Поле "m" — целые числа
k = Int[], # Поле "k" — целые числа
parts = String[], # Поле "parts" — строки (части исходного числа)
multiplied_parts = String[], # Поле "multiplied_parts" — строки (умноженные части)
PQ = String[], # Поле "PQ" — строка результата после умножения частей
NK = String[], # Поле "NK" — строка N * k
result = String[] # Поле "result" — строка с оценкой совпадения
)

count_full = Atomic{Int}(0)  # Счётчик полных совпадений
count_partial_start = Atomic{Int}(0)  # Только начало
count_partial_end = Atomic{Int}(0)  # Только конец
count_partial_both = Atomic{Int}(0)  # И начало, и конец
count_none = Atomic{Int}(0)  # Нет совпадений

@showprogress "🚀 Проверяем N ∈ [$start_N, $stop_N], m = $m, k = $k" for N in start_N:stop_N  # Отображаем прогресс
res = check_algoritm(N, m, k)  # Выполняем проверку для конкретного N

Threads.atomic_add!(count_full, res.result == "✅ Полное совпадение" ? 1 : 0)  # Обновляем счётчики
Threads.atomic_add!(count_partial_start, res.result == "🔄 Совпадает только начало" ? 1 : 0) # Увеличиваем счётчик частичных совпадений (только начало)
Threads.atomic_add!(count_partial_end, res.result == "🔄 Совпадает только конец" ? 1 : 0) # Увеличиваем счётчик частичных совпадений (только конец)
Threads.atomic_add!(count_partial_both, res.result == "🔄 Совпадают начало и конец" ? 1 : 0) # Увеличиваем счётчик частичных совпадений (начало и конец)
Threads.atomic_add!(count_none, res.result == "❌ Нет совпадений" ? 1 : 0) # Увеличиваем счётчик случаев без совпадений

push!(results_df, [  # Добавляем результаты по текущему числу N в DataFrame
res.N # Исходное число N
res.m # Количество частей m
res.k # Множитель k
res.parts # Строковое представление разбиения на части
res.multiplied_parts  # Строковое представление умноженных частей
res.PQ # Результат PQ после объединения (очищенный)
res.NK # Результат NK = N * k (очищенный)
res.result # Результат сравнения: полное или частичное совпадение / нет
])
end

full = count_full[] # Получаем финальное значение счётчика полных совпадений
partial_start = count_partial_start[] # Получаем финальное значение счётчика совпадений только начала
partial_end = count_partial_end[] # Получаем финальное значение счётчика совпадений только конца
partial_both = count_partial_both[] # Получаем финальное значение счётчика совпадений начала и конца
none = count_none[] # Получаем финальное значение счётчика отсутствия совпадений

println("\n💾 Сохраняю результаты в CSV...") # Сохранение статистики в файл
CSV.write("results.csv", results_df)  # Записываем таблицу результатов в файл CSV

open("statistics.txt", "w") do io  # Открываем файл для записи статистики в режиме перезаписи
write(io, "📊 Структурная числовая симметрия\n")
write(io, "=========================================\n")
write(io, "Диапазон N: [$start_N, $stop_N]\n")
write(io, "Количество частей m = $m\n")
write(io, "Множитель k = $k\n")
write(io, "-----------------------------------------\n")
write(io, "  ✅ Полных совпадений: $full\n")
write(io, "  🔄 Совпадают начало и конец: $partial_both\n")
write(io, "  🔄 Совпадает только начало: $partial_start\n")
write(io, "  🔄 Совпадает только конец: $partial_end\n")
write(io, "  ❌ Без совпадений: $none\n")
write(io, "📄 Результаты по каждому числу — в 'results.csv'\n")
end

println("\n📊 Сводная статистика:") # Вывод статистики в терминал
@printf("  ✅ Полных совпадений: %d\n", full) # Печатаем количество полных совпадений
@printf("  🔄 Совпадают начало и конец: %d\n", partial_both) # Печатаем количество совпадений начала и конца
@printf("  🔄 Совпадает только начало: %d\n", partial_start) # Печатаем количество совпадений только начала
@printf("  🔄 Совпадает только конец: %d\n", partial_end) # Печатаем количество совпадений только конца
@printf("  ❌ Без совпадений: %d\n", none) # Печатаем количество отсутствующих совпадений
println("\n📄 Статистика сохранена в 'statistics.txt'") # Выводим в консоль сообщение о сохранении статистики
println("📄 Результаты сохранены в 'results.csv'") # Выводим сообщение о сохранении результатов

return results_df  # Возвращаем заполненную таблицу результатов (DataFrame)
end

# Пользовательские параметры
start_N = 1 # Начальное число диапазона проверки
stop_N = 10000000 # Конечное число диапазона проверки
m = 2 # Число, на которое разбивается исходное число
k = 7 # Множитель, на который умножаются части числа

# Запуск тестов
run_tests_parallel(start_N, stop_N, m, k)  # Вызываем основную функцию для параллельной проверки СЧС
