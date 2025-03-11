## Работа с журналами

### Запуск PGBENCH:
```
daemom@VM2:~$ sudo -u postgres  pgbench -P 60 -T 600
pgbench (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
starting vacuum...end.
progress: 60.0 s, 146.4 tps, lat 6.827 ms stddev 9.147, 0 failed
progress: 120.0 s, 166.3 tps, lat 6.012 ms stddev 7.953, 0 failed
progress: 180.0 s, 216.5 tps, lat 4.616 ms stddev 5.839, 0 failed
progress: 240.0 s, 178.1 tps, lat 5.617 ms stddev 7.394, 0 failed
progress: 300.0 s, 180.1 tps, lat 5.552 ms stddev 7.223, 0 failed
progress: 360.0 s, 176.9 tps, lat 5.651 ms stddev 7.404, 0 failed
progress: 420.0 s, 243.8 tps, lat 4.100 ms stddev 4.773, 0 failed
progress: 480.0 s, 204.8 tps, lat 4.881 ms stddev 6.448, 0 failed
progress: 540.0 s, 108.5 tps, lat 9.219 ms stddev 10.789, 0 failed
progress: 600.0 s, 138.0 tps, lat 7.241 ms stddev 9.355, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 105569
number of failed transactions: 0 (0.000%)
latency average = 5.683 ms
latency stddev = 7.564 ms
initial connection time = 6.175 ms
tps = 175.945019 (without initial connection time)
```
### Анализ журналов: 
В моем случае создавалось не более 6 файлов каждый размером около 16MB. Некоторые файлы были созданы более чем за 30 секунд, это можно объяснить тем, что у нас была выставлено очень частое создание конторльных точек и при нагрузке они не всегда успевают создаваться по времени настройки:  
![NEWVOLUME](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/pgwall.JPG?raw=true)

### Запуск PGBENCH d асинхронном режиме

```
daemom@VM2:~$ sudo -u postgres  pgbench -P 60 -T 600
pgbench (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
starting vacuum...end.
progress: 60.0 s, 579.2 tps, lat 1.726 ms stddev 1.733, 0 failed
progress: 120.0 s, 550.7 tps, lat 1.815 ms stddev 1.793, 0 failed
progress: 180.0 s, 1218.2 tps, lat 0.820 ms stddev 1.668, 0 failed
progress: 240.0 s, 418.4 tps, lat 2.389 ms stddev 2.207, 0 failed
progress: 300.0 s, 558.0 tps, lat 1.792 ms stddev 1.774, 0 failed
progress: 360.0 s, 1140.6 tps, lat 0.876 ms stddev 1.496, 0 failed
progress: 420.0 s, 483.7 tps, lat 2.067 ms stddev 1.803, 0 failed
progress: 480.0 s, 536.7 tps, lat 1.863 ms stddev 1.753, 0 failed
progress: 540.0 s, 680.7 tps, lat 1.469 ms stddev 1.592, 0 failed
progress: 600.0 s, 611.9 tps, lat 1.633 ms stddev 1.622, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 406681
number of failed transactions: 0 (0.000%)
latency average = 1.475 ms
latency stddev = 1.781 ms
initial connection time = 6.584 ms
tps = 677.803661 (without initial connection time)
```
В асинхронном режинме tps на порядок больше поскольку запись в журнал происходит гораздо реже.

### Включаем котрольную сумму

```
postgres=# show data_checksums;
 data_checksums
----------------
 on
(1 row)
```
### Создаем таблицу и вставляем данные:
```
postgres=# CREATE TABLE test_check_sum(id serial,tname char(100));
CREATE TABLE
postgres=# INSERT INTO test_check_sum(tname) SELECT 'testdata' FROM generate_series(1,100000);
INSERT 0 100000
postgres=#  SELECT pg_relation_filepath('test_check_sum');
```
### Находим таблицу:
```
postgres=#  SELECT pg_relation_filepath('test_check_sum');
 pg_relation_filepath
----------------------
 base/5/16828
(1 row)
```

### Меняем содержимое:

```
Стоп кластера:
daemom@VM2:/var/lib/postgresql/15$ sudo pg_ctlcluster 15 main stop
```
Добавлем символы:
![NEWVOLUME](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/edit.JPG?raw=true)
```
Старт кластера:
daemom@VM2:/var/lib/postgresql/15$ sudo pg_ctlcluster 15 main start
```
### Выполняем запрос:

```
postgres=# select * from test_check_sum;
WARNING:  page verification failed, calculated checksum 15121 but expected 12624
ERROR:  invalid page in block 0 of relation base/5/16828
```
Произошла ошибка при проверке контрольной суммы. Для объождения проблемы можно выпольнить команду:  
alter system set ignore_checksum_failure = on;
