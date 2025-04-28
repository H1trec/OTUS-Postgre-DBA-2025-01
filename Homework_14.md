### Работа с join'ами

Для домашней работы была выбрана Демо база с сайта https://postgrespro.ru/education/demodb. 
Основной сущностью является бронирование (bookings).

В одно бронирование можно включить несколько пассажиров, каждому из которых выписывается отдельный билет (tickets).   
 Билет имеет уникальный номер и содержит информацию о пассажире. Как таковой пассажир не является отдельной сущностью.   
 Как имя, так и номер документа пассажира могут меняться с течением времени, так что невозможно однозначно найти все билеты одного человека; для простоты можно считать, что все пассажиры уникальны.   
Билет включает один или несколько перелетов (ticket_flights). Несколько перелетов могут включаться в билет в случаях, когда нет прямого рейса, соединяющего пункты отправления и назначения (полет с пересадками),   
 либо когда билет взят «туда и обратно». В схеме данных нет жёсткого ограничения, но предполагается, что все билеты в одном бронировании имеют одинаковый набор перелетов.   
Каждый рейс (flights) следует из одного аэропорта (airports) в другой. Рейсы с одним номером имеют одинаковые пункты вылета и назначения, но будут отличаться датой отправления.   
При регистрации на рейс пассажиру выдаётся посадочный талон (boarding_passes), в котором указано место в самолете. Пассажир может зарегистрироваться только на тот рейс, который есть у него в билете.   
Комбинация рейса и места в самолете должна быть уникальной, чтобы не допустить выдачу двух посадочных талонов на одно место.   
Количество мест (seats) в самолете и их распределение по классам обслуживания зависит от модели самолета (aircrafts), выполняющего рейс.   
Предполагается, что каждая модель самолета имеет только одну компоновку салона. Схема данных не контролирует,   
что места в посадочных талонах соответствуют имеющимся в самолете (такая проверка может быть сделана с использованием табличных триггеров или в приложении).

Список таблиц:   
```
       Имя       |     Тип       |  Small | Medium |   Big  |       Описание
-----------------+---------------+--------+--------+--------+-------------------------
 aircrafts       | представление |        |        |        | Самолеты
 aircrafts_data  | таблица       |  16 kB |  16 kB |  16 kB | Самолеты (переводы)
 airports        | представление |        |        |        | Аэропорты
 airports_data   | таблица       |  56 kB |  56 kB |  56 kB | Аэропорты (переводы)
 boarding_passes | таблица       |  31 MB | 102 MB | 427 MB | Посадочные талоны
 bookings        | таблица       |  13 MB |  30 MB | 105 MB | Бронирования
 flights         | таблица       |   3 MB |   6 MB |  19 MB | Рейсы
 flights_v       | представление |        |        |        | Рейсы
 routes          | представление |        |        |        | Маршруты
 seats           | таблица       |  88 kB |  88 kB |  88 kB | Места
 ticket_flights  | таблица       |  64 MB | 145 MB | 516 MB | Перелеты
 tickets         | таблица       |  47 MB | 107 MB | 381 MB | Билеты
 ````
bookings.aircrafts:   
```
    Столбец    |   Тип   | Модификаторы |             Описание
---------------+---------+--------------+-----------------------------------
 aircraft_code | char(3) | not null     | Код самолета, IATA
 model         | text    | not null     | Модель самолета
 range         | integer | not null     | Максимальная дальность полета, км
```
bookings.airports_data:
```
   Столбец    |   Тип   | Модификаторы |                 Описание
--------------+---------+--------------+--------------------------------------------
 airport_code | char(3) | not null     | Код аэропорта
 airport_name | jsonb   | not null     | Название аэропорта
 city         | jsonb   | not null     | Город
 coordinates  | point   | not null     | Координаты аэропорта (долгота и широта)
 timezone     | text    | not null     | Часовой пояс аэропорта
```

bookings.airports:
```
 Столбец    |   Тип   | Модификаторы |                 Описание
--------------+---------+--------------+--------------------------------------------
 airport_code | char(3) | not null     | Код аэропорта
 airport_name | text    | not null     | Название аэропорта
 city         | text    | not null     | Город
 coordinates  | point   | not null     | Координаты аэропорта (долгота и широта)
 timezone     | text    | not null     | Часовой пояс аэропорта
```
bookings.boarding_passes:
```
 Столбец   |    Тип     | Модификаторы |         Описание
-------------+------------+--------------+--------------------------
 ticket_no   | char(13)   | not null     | Номер билета
 flight_id   | integer    | not null     | Идентификатор рейса
 boarding_no | integer    | not null     | Номер посадочного талона
 seat_no     | varchar(4) | not null     | Номер места
```
bookings.bookings:
```
 Столбец    |      Тип      | Модификаторы |         Описание
--------------+---------------+--------------+---------------------------
 book_ref     | char(6)       | not null     | Номер бронирования
 book_date    | timestamptz   | not null     | Дата бронирования
 total_amount | numeric(10,2) | not null     | Полная сумма бронирования
```
bookings.flights:
```
      Столбец       |     Тип     | Модификаторы |          Описание
---------------------+-------------+--------------+-----------------------------
 flight_id           | serial      | not null     | Идентификатор рейса
 flight_no           | char(6)     | not null     | Номер рейса
 scheduled_departure | timestamptz | not null     | Время вылета по расписанию
 scheduled_arrival   | timestamptz | not null     | Время прилёта по расписанию
 departure_airport   | char(3)     | not null     | Аэропорт отправления
 arrival_airport     | char(3)     | not null     | Аэропорт прибытия
 status              | varchar(20) | not null     | Статус рейса
 aircraft_code       | char(3)     | not null     | Код самолета, IATA
 actual_departure    | timestamptz |              | Фактическое время вылета
 actual_arrival      | timestamptz |              | Фактическое время прилёта
```
bookings.seats:
```
     Столбец     |     Тип     | Модификаторы |      Описание
-----------------+-------------+--------------+--------------------
 aircraft_code   | char(3)     | not null     | Код самолета, IATA
 seat_no         | varchar(4)  | not null     | Номер места
 fare_conditions | varchar(10) | not null     | Класс обслуживания
```
bookings.ticket_flights:
```
     Столбец     |     Тип       | Модификаторы |    Описание
-----------------+---------------+--------------+---------------------
 ticket_no       | char(13)      | not null     | Номер билета
 flight_id       | integer       | not null     | Идентификатор рейса
 fare_conditions | varchar(10)   | not null     | Класс обслуживания
 amount          | numeric(10,2) | not null     | Стоимость перелета
```
bookings.tickets:
```
     Столбец    |     Тип     | Модификаторы |          Описание
----------------+-------------+--------------+-----------------------------
 ticket_no      | char(13)    | not null     | Номер билета
 book_ref       | char(6)     | not null     | Номер бронирования
 passenger_id   | varchar(20) | not null     | Идентификатор пассажира
 passenger_name | text        | not null     | Имя пассажира
 contact_data   | jsonb       |              | Контактные данные пассажира
 ```
#### Прямое соединение

В данном запросе выводится топ 10 пассажиров, совершмвых больше всех полетов с укзанием количества перелетов и потраченных денег.
```
demo=# SELECT  passenger_name,count(bp.flight_id) flights,sum(b.total_amount) total_amount
demo-# FROM bookings.tickets t
demo-# join bookings.boarding_passes  bp on bp.ticket_no=t.ticket_no
demo-# join bookings.bookings b on b.book_ref=t.book_ref
demo-# join bookings.flights f on bp.flight_id=f.flight_id
demo-# group by passenger_id, passenger_name
demo-# order by count(bp.flight_id) desc
demo-# limit 10;
   passenger_name    | flights | total_amount
---------------------+---------+--------------
 NIKOLAY VLASOV      |       6 |   1030800.00
 ALENA BORISOVA      |       6 |    234000.00
 OLGA IVANOVA        |       6 |    775200.00
 OLGA EGOROVA        |       6 |    194400.00
 VLADIMIR AFANASEV   |       6 |    583200.00
 LARISA MIRONOVA     |       6 |    547200.00
 VALENTINA ZHUKOVA   |       6 |    158400.00
 VLADIMIR GORBUNOV   |       6 |    232200.00
 VYACHESLAV STEPANOV |       6 |   2221800.00
 SERGEY NAZAROV      |       6 |    504000.00
(10 rows)
```
 
#### Кросс соединение таблиц

В данном запросе реализцуется вывод информации о сущестующих посадочных местах в разных тиапх самолетов.
```
demo=# SELECT ad.model,s.seat_no,s.fare_conditions FROM bookings.aircrafts ad
demo-# cross join bookings.seats s where ad.aircraft_code=s.aircraft_code
demo-# LIMIT 10;
      model       | seat_no | fare_conditions
------------------+---------+-----------------
 Аэробус A319-100 | 2A      | Business
 Аэробус A319-100 | 2C      | Business
 Аэробус A319-100 | 2D      | Business
 Аэробус A319-100 | 2F      | Business
 Аэробус A319-100 | 3A      | Business
 Аэробус A319-100 | 3C      | Business
 Аэробус A319-100 | 3D      | Business
 Аэробус A319-100 | 3F      | Business
 Аэробус A319-100 | 4A      | Business
 Аэробус A319-100 | 4C      | Business
(10 rows)
```

#### Полное соединение

 В данном запросе выполнено полное соединение 3-х таблиц, для вывода свободных мест, дело в том,  
 что для данной БД нет примеров данных из двух и более таблиц где при полной соединении были бы отсутвующие записи и в той и в той таблице, т.к. так устроено храниение.
```
demo=# SELECT  f.flight_no, f.scheduled_departure, bp.seat_no as bp_seat_no,s.seat_no
demo-# FROM bookings.flights f
demo-# full join bookings.seats s on f.aircraft_code=s.aircraft_code
demo-# full join bookings.boarding_passes  bp on bp.flight_id=f.flight_id and s.seat_no=bp.seat_no
demo-# where flight_no='PG0216'
demo-# limit 20;
 flight_no |  scheduled_departure   | bp_seat_no | seat_no
-----------+------------------------+------------+---------
 PG0216    | 2016-08-15 11:10:00+00 | 11A        | 11A
 PG0216    | 2016-08-15 11:10:00+00 |            | 11B
 PG0216    | 2016-08-15 11:10:00+00 |            | 11D
 PG0216    | 2016-08-15 11:10:00+00 |            | 11E
 PG0216    | 2016-08-15 11:10:00+00 |            | 11F
 PG0216    | 2016-08-15 11:10:00+00 |            | 11G
 PG0216    | 2016-08-15 11:10:00+00 |            | 11H
 PG0216    | 2016-08-15 11:10:00+00 | 12A        | 12A
 PG0216    | 2016-08-15 11:10:00+00 |            | 12B
 PG0216    | 2016-08-15 11:10:00+00 | 12D        | 12D
 PG0216    | 2016-08-15 11:10:00+00 |            | 12E
 PG0216    | 2016-08-15 11:10:00+00 |            | 12F
 PG0216    | 2016-08-15 11:10:00+00 |            | 12G
 PG0216    | 2016-08-15 11:10:00+00 | 12H        | 12H
 PG0216    | 2016-08-15 11:10:00+00 | 13A        | 13A
 PG0216    | 2016-08-15 11:10:00+00 |            | 13B
 PG0216    | 2016-08-15 11:10:00+00 | 13D        | 13D
 PG0216    | 2016-08-15 11:10:00+00 | 13E        | 13E
 PG0216    | 2016-08-15 11:10:00+00 |            | 13F
 PG0216    | 2016-08-15 11:10:00+00 | 13G        | 13G
(20 rows)
```

#### Разные типы соединений(праямое и левостороннее)

В данном запросе реализуется подсчет процеснта заполняемости определнного рейса по разным датам вылета.   
```
demo=# SELECT  f.flight_no, f.scheduled_departure, round((count(bp.seat_no)::NUMERIC /count(s.seat_no))*100,2) as prc_seats
demo-# FROM bookings.flights f
demo-# join bookings.seats s on f.aircraft_code=s.aircraft_code
demo-# left join bookings.boarding_passes  bp on bp.flight_id=f.flight_id and s.seat_no=bp.seat_no
demo-# where flight_no='PG0216'
demo-# group by f.flight_no, f.scheduled_departure
demo-# limit 20;
 flight_no |  scheduled_departure   | prc_seats
-----------+------------------------+-----------
 PG0216    | 2016-08-15 11:10:00+00 |     34.68
 PG0216    | 2016-08-16 11:10:00+00 |     41.89
 PG0216    | 2016-08-17 11:10:00+00 |     38.29
 PG0216    | 2016-08-18 11:10:00+00 |     44.59
 PG0216    | 2016-08-19 11:10:00+00 |     42.79
 PG0216    | 2016-08-20 11:10:00+00 |     42.79
 PG0216    | 2016-08-21 11:10:00+00 |     47.30
 PG0216    | 2016-08-22 11:10:00+00 |     56.31
 PG0216    | 2016-08-23 11:10:00+00 |     50.90
 PG0216    | 2016-08-24 11:10:00+00 |     57.21
 PG0216    | 2016-08-25 11:10:00+00 |     64.41
 PG0216    | 2016-08-26 11:10:00+00 |     63.06
 PG0216    | 2016-08-27 11:10:00+00 |     57.66
 PG0216    | 2016-08-28 11:10:00+00 |     63.06
 PG0216    | 2016-08-29 11:10:00+00 |     62.16
 PG0216    | 2016-08-30 11:10:00+00 |     60.81
 PG0216    | 2016-08-31 11:10:00+00 |     66.22
 PG0216    | 2016-09-01 11:10:00+00 |     65.77
 PG0216    | 2016-09-02 11:10:00+00 |     66.22
 PG0216    | 2016-09-03 11:10:00+00 |     63.96
(20 rows)
```

