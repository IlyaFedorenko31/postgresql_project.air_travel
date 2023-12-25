1. Выведите названия самолётов, которые имеют менее 50 посадочных мест.

select count( distinct seat_no) , a.model 
from seats s 
inner join aircrafts a on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code 
having count (*) < 50

2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

select date_trunc('month', b.book_date) as "месяц", sum(b.total_amount) as "ежемесячная сумма",
round(((sum(total_amount) - lag(sum(total_amount), 1) over (order by date_trunc('month', b.book_date))) / lag(sum(total_amount), 1) over (order by date_trunc('month', b.book_date))) * 100, 2) as "процентное изменение"
from bookings b
group by date_trunc('month', b.book_date)

3. Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg.

select array_agg(distinct s.fare_conditions) as "класс обслуживания", a.model as "модель без бизнес класса"
from seats s 
join aircrafts a on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code
having array_position(array_agg(distinct s.fare_conditions), 'Business') is null

4. Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день. Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.
Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.

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

select dep.airport_name as "аэропорт отбытия", arr.airport_name as "аэропорт прибытия", round(count(*) * 100 / sum(count(*)) over (), 2) as "Процентное отношение"
from flights f
join airports dep on f.departure_airport = dep.airport_code
join airports arr on f.arrival_airport = arr.airport_code
group by dep.airport_name, arr.airport_name

6. Выведите количество пассажиров по каждому коду сотового оператора. Код оператора – это три символа после +7.

select substring (contact_data->>'phone' from 3 for 3) as "Код оператора", count(*) as "Кол-во пассажиров по коду"
from tickets t
group by "Код оператора"             
                
7. Классифицируйте финансовые обороты (сумму стоимости перелетов) по маршрутам:
до 50 млн – low
от 50 млн включительно до 150 млн – middle
от 150 млн включительно – high
Выведите в результат количество маршрутов в каждом полученном классе.

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
                
8*. Вычислите медиану стоимости перелетов, медиану стоимости бронирования и отношение медианы бронирования к медиане стоимости перелетов, результат округлите до сотых. 

select "медиана стоимости бронирования", "медиана стоимости перелёта", round(("медиана стоимости бронирования"::numeric/"медиана стоимости перелёта"::numeric), 2) as "отношение медианы бронирования к медиане стоимости перелёта"
   from 
     (select percentile_cont(0.5) within group (order by amount) as "медиана стоимости перелёта"
      from ticket_flights tf) p1,
     (select percentile_cont(0.5) within group (order by total_amount) as "медиана стоимости бронирования"
      from bookings b) p2
    
9*. Найдите значение минимальной стоимости одного километра полёта для пассажира. Для этого определите расстояние между аэропортами и учтите стоимость перелета. Для поиска расстояния между двумя точками на поверхности Земли используйте дополнительный модуль earthdistance. Для работы данного модуля нужно установить ещё один модуль – cube.

#Важно: 
#Установка дополнительных модулей происходит через оператор CREATE EXTENSION название_модуля.
#В облачной базе данных модули уже установлены.
#Функция earth_distance возвращает результат в метрах.

create extension cube
create extension earthdistance

select (min(tf.amount / earth_distance(ll_to_earth(dep.latitude, dep.longitude), ll_to_earth(arr.latitude, arr.longitude))) * 1000) as "минимальная стоимость"
from flights f
join airports dep on f.departure_airport = dep.airport_code
join airports arr on f.arrival_airport = arr.airport_code
join ticket_flights tf on f.flight_id = tf.flight_id


