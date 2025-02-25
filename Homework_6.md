## Настройка autovacuum с учетом особеностей производительности
### Развернул VM и установил Postgres:
```
daemom@VM3:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

### Проводим инициализацию pgbench:  
```
daemom@VM3:~$ sudo -u postgres pgbench -i postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.09 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.61 s (drop tables 0.00 s, create tables 0.02 s, client-side generate 0.23 s, vacuum 0.08 s, primary keys 0.27 s).
```
### Запускаем тест pgbench:  
```
daemom@VM3:~$ sudo -u postgres  pgbench -c8 -P 6 -T 60
pgbench (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
starting vacuum...end.
progress: 6.0 s, 248.7 tps, lat 31.832 ms stddev 24.490, 0 failed
progress: 12.0 s, 200.8 tps, lat 39.676 ms stddev 32.580, 0 failed
progress: 18.0 s, 260.0 tps, lat 30.818 ms stddev 23.727, 0 failed
progress: 24.0 s, 257.8 tps, lat 30.994 ms stddev 21.034, 0 failed
progress: 30.0 s, 251.2 tps, lat 31.756 ms stddev 23.800, 0 failed
progress: 36.0 s, 262.3 tps, lat 30.498 ms stddev 21.786, 0 failed
progress: 42.0 s, 260.1 tps, lat 30.617 ms stddev 22.476, 0 failed
progress: 48.0 s, 263.2 tps, lat 30.382 ms stddev 21.076, 0 failed
progress: 54.0 s, 254.0 tps, lat 31.577 ms stddev 25.397, 0 failed
progress: 60.0 s, 258.7 tps, lat 30.775 ms stddev 23.629, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 15109
number of failed transactions: 0 (0.000%)
latency average = 31.723 ms
latency stddev = 24.105 ms
initial connection time = 43.265 ms
tps = 251.770651 (without initial connection time)
```
### Применяем настройки:  
```
daemom@VM3:~$ sudo -u postgres psql
could not change directory to "/home/daemom": Permission denied
psql (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
Type "help" for help.

postgres=# ALTER SYSTEM SET max_connections TO '40';
ALTER SYSTEM SET effective_cache_size TO '3GB';
ALTER SYSTEM SET maintenance_work_mem TO '512MB';
ALTER SYSTEM SET checkpoint_completion_target TO '0.9';
ALTER SALTER SYSTEM
postgres=# ALTER SYSTEM SET shared_buffers TO '1GB';
YSTEM SET wal_buffers TO '16MB';
ALTER SYSTEM SET default_statistics_target TO '500';
ALTER SYSTEM SET random_page_cost TO '4';
ALTER SYSTEM SET effective_io_concurrency TO '2';
ALTER SYSTEM SET worALTER SYSTEM
postgres=# ALTER SYSTEM SET effective_cache_size TO '3GB';
k_mem TO '6553kB';
ALTER SYSTEM SET min_wal_size TO '4GB';
ALTER SYSTEM SETALTER SYSTEM
postgres=# ALTER SYSTEM SET maintenance_work_mem TO '512MB';
 max_wal_size TO '16GB';ALTER SYSTEM
postgres=# ALTER SYSTEM SET checkpoint_completion_target TO '0.9';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET wal_buffers TO '16MB';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET default_statistics_target TO '500';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET random_page_cost TO '4';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET effective_io_concurrency TO '2';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET work_mem TO '6553kB';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET min_wal_size TO '4GB';
ALTER SYSTEM
postgres=# ALTER SYSTEM SET max_wal_size TO '16GB';
ALTER SYSTEM
postgres=# \q
```
### Проводим повторный тест:  
```
daemom@VM3:~$ sudo -u postgres  pgbench -c8 -P 6 -T 60
pgbench (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
starting vacuum...end.
progress: 6.0 s, 191.1 tps, lat 41.265 ms stddev 31.816, 0 failed
progress: 12.0 s, 185.2 tps, lat 43.175 ms stddev 33.974, 0 failed
progress: 18.0 s, 242.5 tps, lat 33.033 ms stddev 22.584, 0 failed
progress: 24.0 s, 214.6 tps, lat 37.057 ms stddev 28.908, 0 failed
progress: 30.0 s, 257.0 tps, lat 31.254 ms stddev 23.300, 0 failed
progress: 36.0 s, 269.3 tps, lat 29.634 ms stddev 20.864, 0 failed
progress: 42.0 s, 248.8 tps, lat 32.090 ms stddev 22.779, 0 failed
progress: 48.0 s, 254.2 tps, lat 31.491 ms stddev 23.576, 0 failed
progress: 54.0 s, 265.0 tps, lat 30.153 ms stddev 21.564, 0 failed
progress: 60.0 s, 273.2 tps, lat 29.258 ms stddev 19.160, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 14413
number of failed transactions: 0 (0.000%)
latency average = 33.259 ms
latency stddev = 25.060 ms
initial connection time = 45.087 ms
tps = 240.086972 (without initial connection time)
```
Количество tps уменьшилось при повторном тесте вероятнее всего настройками мы выкрутили сервер на более высокую производительность и при работе avtovacuum начала появляться дополнительная нагрузка на кластер.
### Создаем и заполняем таблицу:
```
daemom@VM3:~$ sudo -u postgres psql
[sudo] password for daemom:
Sorry, try again.
[sudo] password for daemom:
could not change directory to "/home/daemom": Permission denied
psql (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
Type "help" for help.

postgres=# CREATE TABLE test(
postgres(#   id serial,
postgres(#   tname char(100)
postgres(# );
CREATE TABLE
postgres=# INSERT INTO test(tname) SELECT 'testdata' FROM generate_series(1,1000000);
INSERT 0 1000000
postgres=#
```
### Смотрим размер таблицы:
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 135 MB
(1 row)

postgres=#
```
### Делаем update и смотрим количество метрвых строк:
```
postgres=# update test set tname=tname||'f';
UPDATE 1000000
postgres=# update test set tname=tname||'t';
UPDATE 1000000
postgres=# update test set tname=tname||'y';
UPDATE 1000000
postgres=# update test set tname=tname||'u';
UPDATE 1000000
postgres=# update test set tname=tname||'w';
UPDATE 1000000
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum
postgres-# FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 test    |     998875 |    2004973 |    200 | 2025-02-25 18:18:58.317759+00
(1 row)
```
### Видим, что количество мертвых строк стало 0:  
```
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum
FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 test    |    1499418 |          0 |      0 | 2025-02-25 18:20:02.779937+00
(1 row)
```
### Проводим update повторно и смотрим размер таблицы:   
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 808 MB
(1 row)

postgres=#
```
Размер таблицы значительно увеличился.

### Отключаем autovacuum и проводим операции над таблицей:  
```
postgres=# ALTER TABLE test SET (autovacuum_enabled = off);
ALTER TABLE
postgres=# update test set tname=tname||'h';
e=tname||'d';
update test set tname=tname||'m';
update test set tname=tname||'q';
update test set tname=tname||'z';
update test set tname=tname||'o';
update test set tname=tname||'w';
update test set tname=tname||'x';
update test set tname=tname||'v';
update test set tname=tname||'m';
UPDATE 1000000
postgres=# update test set tname=tname||'d';
UPDATE 1000000
postgres=# update test set tname=tname||'m';
UPDATE 1000000
postgres=# update test set tname=tname||'q';
UPDATE 1000000
postgres=# update test set tname=tname||'z';
UPDATE 1000000
postgres=# update test set tname=tname||'o';
UPDATE 1000000
postgres=# update test set tname=tname||'w';
UPDATE 1000000
postgres=# update test set tname=tname||'x';
UPDATE 1000000
postgres=# update test set tname=tname||'v';
UPDATE 1000000
postgres=# update test set tname=tname||'m';
UPDATE 1000000
postgres=# SELECT pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 1482 MB
(1 row)
```
Видим, чт объем таблицы значительно увеличился, это происходит из-за раздутия таблицы, поскольку в ней очень много метрвых строк.

### Задача по автоматическому изменению строк в таблице:

```
postgres=# DO $$
postgres$# BEGIN
postgres$#     FOR i IN 1..10 LOOP
postgres$#         update test set tname=tname||'h';
postgres$#         RAISE NOTICE 'Iteration: %', i;
postgres$#     END LOOP;
postgres$# END $$;
NOTICE:  Iteration: 1
NOTICE:  Iteration: 2
NOTICE:  Iteration: 3
NOTICE:  Iteration: 4
NOTICE:  Iteration: 5
NOTICE:  Iteration: 6
NOTICE:  Iteration: 7
NOTICE:  Iteration: 8
NOTICE:  Iteration: 9
NOTICE:  Iteration: 10
DO
postgres=#
```
