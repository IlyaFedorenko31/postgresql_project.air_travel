Зачтено - #1. Выведите названия самолётов, которые имеют менее 50 посадочных мест.

#select count( distinct seat_no) , a.model 
#from seats s 
#inner join aircrafts a on s.aircraft_code = a.aircraft_code 
#group by a.aircraft_code 
#having count (*) < 50

2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

первое решение (Минус 10 баллов. Не верная работа с месяцами, получаете данные за все года сразу.):

#select book_date::date as "месяц", round(((total_amount - lag(total_amount) over (order by book_date::date))) / lag(total_amount) over (order by book_date::date) * 100, 2) as "процентное изменение"
#from bookings b
#group by book_date::date, b.total_amount 
#order by book_date::date

новое решение:

select date_trunc('month', b.book_date) as "месяц", sum(b.total_amount) as "ежемесячная сумма",
round(((sum(total_amount) - lag(sum(total_amount), 1) over (order by date_trunc('month', b.book_date))) / lag(sum(total_amount), 1) over (order by date_trunc('month', b.book_date))) * 100, 2) as "процентное изменение"
from bookings b
group by date_trunc('month', b.book_date)

3. Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg.

первое решение (0. Решение должно быть через функцию array_agg, а не просто использовать данную функцию просто так, то есть ее нужно использовать для получения результата.
Решение не соответствует условию задания, в задании спрашивают про самолеты, где нет бизнеса, а не про какие-то другие классы.):

#select array_agg(distinct fare_conditions), a.model 
#from seats s 
#inner join aircrafts a on s.aircraft_code = a.aircraft_code 
#where fare_conditions = 'Economy'
#group by a.aircraft_code 

новое решение:

select array_agg(distinct s.fare_conditions) as "класс обслуживания", a.model as "модель без бизнес класса"
from seats s 
join aircrafts a on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code
having array_position(array_agg(distinct s.fare_conditions), 'Business') is null

4. Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день. Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.
Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.

первое решение (0, решение не соответствует условию задания): 

#select f.departure_airport, f.scheduled_departure::date, count(*) AS "пустые места", 
       #sum(count(*)) over (partition by f.flight_no order by f.scheduled_departure::date) as "накопительный итог"                    
#from (ticket_flights tf join flights f on tf.flight_id = f.flight_id)
#left join boarding_passes bp on tf.ticket_no = bp.ticket_no and tf.flight_id = bp.flight_id 
#where f.actual_departure is null and bp.flight_id is null 
#group by f.departure_airport, f.scheduled_departure, f.flight_no 
#having count(*)>1

новое решение: 

select f.aircraft_code, date(f.actual_departure) as "дата вылета", count(distinct s.seat_no) as "кол-во пустых мест", 
 sum(count(*)) over (partition by f.flight_no order by f.actual_departure::date) as "накопительный итог"
from flights f
left join aircrafts a on f.aircraft_code = a.aircraft_code
left join ticket_flights tf on f.flight_id = tf.flight_id
left join boarding_passes bp on tf.flight_id = bp.flight_id
left join seats s on a.aircraft_code = s.aircraft_code
where bp.boarding_no is null
group by f.aircraft_code, date(f.actual_departure), f.flight_no 
 
5. Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. Выведите в результат названия аэропортов и процентное отношение. Используйте в решении оконную функцию.

первое решение (минус 10 баллов - отсутствие названий аэропортов):

#select f.departure_airport, f.arrival_airport, round(count(*) * 100 / sum(count(*)) over (), 2) as "Процентное отношение"
#from flights f
#group by departure_airport, arrival_airport

новое решение:

select dep.airport_name as "аэропорт отбытия", arr.airport_name as "аэропорт прибытия", round(count(*) * 100 / sum(count(*)) over (), 2) as "Процентное отношение"
from flights f
join airports dep on f.departure_airport = dep.airport_code
join airports arr on f.arrival_airport = arr.airport_code
group by dep.airport_name, arr.airport_name

6. Выведите количество пассажиров по каждому коду сотового оператора. Код оператора – это три символа после +7.

первое решение (минус 10 баллов, комментарий: "Код оператора - это три символа после +7, а не три символа после +7 и еще одного символа.":

#select substring (contact_data->>'phone', 4, 3) as "Код оператора", count(*) as "Кол-во пассажиров по коду"
#from tickets t
#where contact_data->>'phone' like '+7%'
#group by "Код оператора"

новое решение:

select substring (contact_data->>'phone' from 3 for 3) as "Код оператора", count(*) as "Кол-во пассажиров по коду"
from tickets t
group by "Код оператора"             
                
7. Классифицируйте финансовые обороты (сумму стоимости перелетов) по маршрутам:
до 50 млн – low
от 50 млн включительно до 150 млн – middle
от 150 млн включительно – high
Выведите в результат количество маршрутов в каждом полученном классе.

первое решение (0, решение не соответствует условию задания):
                
#select case_amount, count(distinct flight_id)
#from (
	#select flight_id, amount,
		#case
			#when amount < 5000 then 'low'
			#when amount between 5000 and 15000 then 'middle'
			#else 'high'
		#end case_amount
	#from ticket_flights tf) tf
#group by case_amount

новое решение:
                
select case_amount, count(*)
from (
    select case
	       when sum(amount) < 50000000 then 'low'
	       when sum(amount) >= 50000000 and sum(amount) < 150000000 then 'middle'
	       else 'high'
	   end case_amount
    from ticket_flights tf 
    join flights f on tf.flight_id = f.flight_id
    group by f.departure_airport, f.arrival_airport) tff
group by case_amount            
                
Зачтено - #8*. Вычислите медиану стоимости перелетов, медиану стоимости бронирования и отношение медианы бронирования к медиане стоимости перелетов, результат округлите до сотых. 

#select "медиана стоимости бронирования", "медиана стоимости перелёта", round(("медиана стоимости бронирования"::numeric/"медиана стоимости перелёта"::numeric), 2) as "отношение медианы бронирования к медиане стоимости перелёта"
   #from 
     #(select percentile_cont(0.5) within group (order by amount) as "медиана стоимости перелёта"
      #from ticket_flights tf) p1,
     #(select percentile_cont(0.5) within group (order by total_amount) as "медиана стоимости бронирования"
      #from bookings b) p2
    
    
Зачтено - #9*. Найдите значение минимальной стоимости одного километра полёта для пассажира. Для этого определите расстояние между аэропортами и учтите стоимость перелета. Для поиска расстояния между двумя точками на поверхности Земли используйте дополнительный модуль earthdistance. Для работы данного модуля нужно установить ещё один модуль – cube.

#Важно: 
#Установка дополнительных модулей происходит через оператор CREATE EXTENSION название_модуля.
#В облачной базе данных модули уже установлены.
#Функция earth_distance возвращает результат в метрах.

#create extension cube
#create extension earthdistance

#select (min(tf.amount / earth_distance(ll_to_earth(dep.latitude, dep.longitude), ll_to_earth(arr.latitude, arr.longitude))) * 1000) as "минимальная стоимость"
#from flights f
#join airports dep on f.departure_airport = dep.airport_code
#join airports arr on f.arrival_airport = arr.airport_code
#join ticket_flights tf on f.flight_id = tf.flight_id


