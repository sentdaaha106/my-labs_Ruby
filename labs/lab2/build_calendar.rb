

require 'date'

# проверяем аргументы командной строки
if ARGV.length != 4
  puts "Ошибка! Нужно указать 4 аргумента:"
  puts "ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt"
  exit 1
end

# получаем аргументы
teams_file = ARGV[0]
start_date_str = ARGV[1]
end_date_str = ARGV[2]
output_file = ARGV[3]

# проверяем даты
begin
  start_date = Date.parse(start_date_str)
  end_date = Date.parse(end_date_str)
  
  if start_date > end_date
    puts "Ошибка! Дата начала не может быть позже даты окончания"
    exit 1
  end
rescue ArgumentError
  puts "Ошибка! Неправильный формат даты. Используйте ДД.ММ.ГГГГ"
  exit 1
end

# читаем команды из файла
begin
  teams = []
  cities = []
  
  File.open(teams_file, "r:UTF-8") do |file|
    file.each_line do |line|
      next if line.strip.empty?
      
      # разбираем строку: "1. Изумрудные Стражи — Изумрудград"
      if line =~ /^\d+\.\s+(.+?)\s+[—–]\s+(.+)$/
        team_name = $1.strip
        city = $2.strip
        
        teams << team_name
        cities << city
      else
        puts "Предупреждение: неправильный формат строки: #{line}"
      end
    end
  end
  
  if teams.empty?
    puts "Ошибка! Не найдено ни одной команды в файле"
    exit 1
  end
  
  puts "Загружено команд: #{teams.length}"
  
rescue Errno::ENOENT
  puts "Ошибка! Файл #{teams_file} не найден"
  exit 1
end

# создаем список всех возможных игр (только команды из разных городов)
all_games = []
(0...teams.length).each do |i|
  (i+1...teams.length).each do |j|
    if cities[i] != cities[j]
      all_games << {
        team1: teams[i],
        team2: teams[j],
        city1: cities[i],
        city2: cities[j]
      }
    end
  end
end

puts "Всего возможных игр: #{all_games.length}"
all_games = all_games.shuffle

# находим все игровые дни (пятница, суббота, воскресенье)
game_days = []
current_date = start_date

while current_date <= end_date
  # 5 = пятница, 6 = суббота, 0 = воскресенье
  if [5, 6, 0].include?(current_date.wday)
    game_days << current_date
  end
  current_date = current_date.next_day
end

puts "Игровых дней в диапазоне: #{game_days.length}"

# время начала игр
game_times = ["12:00", "15:00", "18:00"]

# распределяем игры по дням
calendar = []
games_used = 0
games_per_day = (all_games.length.to_f / game_days.length).ceil

game_days.each do |day|
  games_today = [games_per_day, all_games.length - games_used].min
  
  games_today.times do
    if games_used < all_games.length
      game = all_games[games_used]
      time = game_times.sample
      
      calendar << {
        date: day,
        time: time,
        team1: game[:team1],
        team2: game[:team2],
        city1: game[:city1],
        city2: game[:city2]
      }
      
      games_used += 1
    end
  end
end

# сортируем игры по дате и времени
calendar.sort_by! { |game| [game[:date], game[:time]] }

# функция для русского названия дня недели
def ru_weekday(wday)
  days = ["воскресенье", "понедельник", "вторник", "среда", 
          "четверг", "пятница", "суббота"]
  days[wday]
end

# записываем календарь в файл
begin
  File.open(output_file, "w:UTF-8") do |file|
    file.puts "=" * 80
    file.puts "СПОРТИВНЫЙ КАЛЕНДАРЬ"
    file.puts "Период: #{start_date_str} - #{end_date_str}"
    file.puts "Всего игр: #{games_used}"
    file.puts "=" * 80
    file.puts
    
    current_date = nil
    
    calendar.each do |game|
      if current_date != game[:date]
        current_date = game[:date]
        file.puts
        file.puts "--- #{game[:date].strftime('%d.%m.%Y')} (#{ru_weekday(game[:date].wday)}) ---"
        file.puts "-" * 40
      end
      
      file.puts "#{game[:time]} | #{game[:team1]} (г. #{game[:city1]}) vs #{game[:team2]} (г. #{game[:city2]})"
    end
    
    file.puts
    file.puts "=" * 80
    file.puts "Календарь составлен: #{Time.now.strftime('%d.%m.%Y %H:%M')}"
  end
  
  puts "Готово! Календарь сохранен в файл: #{output_file}"
  
rescue Errno::EACCES
  puts "Ошибка! Нет прав для записи в файл #{output_file}"
  exit 1
end

# статистика
puts "\nСтатистика:"
puts "Всего игр в календаре: #{calendar.length}"