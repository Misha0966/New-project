using Printf  # Используется для форматированного вывода (например, @printf)

# Функция разбивает число N как строку на m частей 
function split_number_str(N::String, m::Integer)
len = length(N) # Длина строки N
base_len = div(len, m) # Базовая длина каждой части при делении на m
remainder = len % m # Остаток от деления длины N на m

parts = String[] # Массив для хранения частей
idx = 1 # Текущий индекс начала следующей части

for i in 1:m  # Цикл по количеству частей
current_len = base_len + (i <= remainder ? 1 : 0)  # Добавляем +1 к длине первым "remainder" частям
push!(parts, N[idx:idx+current_len-1]) # Добавляем подстроку в массив частей
idx += current_len # Сдвигаем индекс на начало следующей части
end

return parts # Возвращаем массив строковых частей
end

# Умножает часть числа, сохраняя длину
function multiply_preserve_length(part::String, k::Integer)
num = parse(BigInt, part) * k  # Преобразуем строку в BigInt и умножаем на k
result = string(num)  # Обратно преобразуем в строку

return lpad(result, max(length(part), length(result)), '0') # Если результат короче исходной части — дополняем нулями слева

end

# Проверка СЧС для одного числа с определением всех классов
function check_full_match_for_one_number(N::BigInt, m::Integer, k::Integer)
N_str = string(N)                         # Преобразуем N в строку
parts = split_number_str(N_str, m)        # Разбиваем N на m частей

pq_parts = [multiply_preserve_length(part, k) for part in parts] # Умножаем каждую часть и сохраняем как строки с сохранением длины

pq_str = join(pq_parts) # Объединяем умноженные части — это PQ

nk_str = string(N * k) # Умножаем всё число целиком — это NK

# Проверяем совпадение границ
first_match = !isempty(pq_str) && !isempty(nk_str) && first(pq_str) == first(nk_str) # Совпадает ли первая цифра
last_match = !isempty(pq_str) && !isempty(nk_str) && last(pq_str) == last(nk_str) # Совпадает ли последняя цифра

# Определяем класс по правилам СЧС
is_F = pq_str == nk_str # Класс F: полное совпадение PQ и NK
is_B = first_match && last_match && !is_F # Класс B: совпадают начало И конец, но не полное совпадение
is_E = last_match && !first_match # Класс E: совпадает ТОЛЬКО конец
is_S = first_match && !last_match # Класс S: совпадает ТОЛЬКО начало
is_N = !first_match && !last_match # Класс N: нет совпадений ни начала, ни конца

@printf("🔢 N = %s\n", N_str) # Выводим N
@printf("📐 m = %d\n", m) # Выводим количество частей
@printf("🧮 k = %d\n", k) # Выводим коэффициент умножения

@printf("🛠 Разбиение:\n") # Выводим заголовок для разбиения
for (i, part) in enumerate(parts) # Перечисляем все части
@printf("   Часть %d: \"%s\"\n", i, part) # Выводим каждую часть
end

@printf("➡️ Умноженные части:\n") # Выводим заголовок для умноженных частей
for (i, part) in enumerate(pq_parts)  # Перечисляем умноженные части
@printf("   Часть %d: \"%s\"\n", i, part) # Выводим каждую умноженную часть
end

@printf("📌 PQ = %s\n", pq_str) # Выводим PQ
@printf("📌 NK = %s\n", nk_str) # Выводим NK

# Определяем имя класса для вывода и файла
class_name = is_F ? "F" : is_B ? "B" : is_E ? "E" : is_S ? "S" : "N" # Выбираем класс по приоритету

# Выводим результат в зависимости от класса
if is_F
@printf("✅ Класс F: Полное совпадение найдено!\n") # Полное совпадение
elseif is_B
@printf("✅ Класс B: Совпадение начала и конца найдено!\n") # Начало и конец
elseif is_E
@printf("✅ Класс E: Совпадение только конца найдено!\n") # Только конец
elseif is_S
@printf("✅ Класс S: Совпадение только начала найдено!\n") # Только начало
elseif is_N
@printf("❌ Класс N: Нет совпадений.\n") # Нет совпадений
end

filename = "class_$(class_name)_N$(N_str[1:min(50, length(N_str))]...)_m$m.txt"  # Генерируем имя файла с классом

open(filename, "w") do io # Открываем файл на запись
write(io, "📊 Структуральная числовая симметрия\n")
write(io, "=========================================\n")
write(io, "🔢 N = $N_str\n")
write(io, "📐 m = $m\n")
write(io, "🧮 k = $k\n")
write(io, "-----------------------------------------\n")
write(io, "🛠 Разбиение:\n")
for (i, part) in enumerate(parts)
write(io, "   Часть $i: \"$part\", длина: $(length(part))\n")
end
write(io, "➡️ Умноженные части:\n")
for (i, part) in enumerate(pq_parts)
write(io, "   Часть $i: \"$part\", длина: $(length(part))\n")
end
write(io, "📌 PQ = $pq_str\n")
write(io, "📌 NK = $nk_str\n")
write(io, "-----------------------------------------\n")
write(io, "✅ Класс: $class_name\n") # Записываем определённый класс
write(io, "=========================================\n")
end

println("\n📄 Результаты сохранены в файл: $filename") # Сообщение о сохранении

return ( # Возвращаем структуру с результатом
N = N,
m = m,
k = k,
PQ = pq_str,
NK = nk_str,
class = class_name # Возвращаем имя класса вместо булева результата
    )
end

# Пользовательский раздел
println("🔄 Вычисляем N = 9999^9999...") # Пример: N = 9999^9999 большое число
N_bigint = big(9999)^9999 # Можно заменить на гораздо меньшие числа
m = 2 # количество частей
k = 3 # k — натуральное число

# Запуск проверки
check_full_match_for_one_number(N_bigint, m, k)
