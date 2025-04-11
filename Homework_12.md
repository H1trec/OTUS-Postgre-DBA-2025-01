### Бэкапы

#### Создание БД и таблицы

Заходим в Postgres:   
```
daemom@OVMPG:~$ sudo -u postgres psql
[sudo] password for daemom:
could not change directory to "/home/daemom": Permission denied
Password for user postgres:
psql (15.12 (Ubuntu 15.12-1.pgdg24.10+1))
Type "help" for help.

postgres=#
```

Создаем БД и таблицу с данными:

```
postgres=# create database test;
CREATE DATABASE
postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# create table student as
test-# select
test-#   generate_series(1,100) as id,
test-#   md5(random()::text)::char(10) as fio;
ERROR:  relation "student" already exists
test=# drop table student;
DROP TABLE
test=# create table student as
test-# select
test-#   generate_series(1,100) as id,
test-#   md5(random()::text)::char(10) as fio;
SELECT 100
```
Создаем каталог для бэкапов:  

```
daemom@OVMPG:~$ sudo -i -u postgres
[sudo] password for daemom:
postgres@OVMPG:~$
postgres@OVMPG:/tmp$ mkdir bcp
postgres@OVMPG:/tmp$ cd bcp
postgres@OVMPG:/tmp/bcp$

```
#### Логический бэкап 
Делаем логический бекап:  
```
test=# \copy student to '/tmp/bcp/st.sql' with delimiter ',' ;
COPY 100
test=#
```

Создаем вторую таблицу:
```
test=# create table student2 ( id integer , fio char(10));
CREATE TABLE
```
Восстанавливаем данные во вторую таблицу и проверяем корректность:
```
test=# \copy student2 from '/tmp/bcp/st.sql' with delimiter ',' ;
COPY 100
test=# select count(*) from student2;
 count
-------
   100
(1 row)

test=# select * from student2 limit 10;
 id |    fio
----+------------
  1 | 760308c5b0
  2 | 17cf96fea0
  3 | 3b8143c944
  4 | 4495df6c71
  5 | 85a183b7e6
  6 | 5892b44e0b
  7 | 5f2d139432
  8 | b8e5474a0b
  9 | 1bc746c7a1
 10 | dad56d1322
(10 rows)

test=# select * from student limit 10;
 id |    fio
----+------------
  1 | 760308c5b0
  2 | 17cf96fea0
  3 | 3b8143c944
  4 | 4495df6c71
  5 | 85a183b7e6
  6 | 5892b44e0b
  7 | 5f2d139432
  8 | b8e5474a0b
  9 | 1bc746c7a1
 10 | dad56d1322
(10 rows)

```
Данные восстановились и совпадают с первой таблицей.

#### pg_dump и pg_restore

Делаем сжатую копию:
```
postgres@OVMPG:/tmp/bcp$ pg_dump -d test --create -U postgres -Fc -p 5432 > /tmp/bcp/arh2.gz
```

Создаем вторую БД:
```
test=# create database test2;
CREATE DATABASE
test=# \c test2;
You are now connected to database "test2" as user "postgres".
test2=#
```

Восстанавливаем только вторую таблицу и проверяем данные:
```
pg_restore -d test2 -t student2 -U postgres -p 5432 /tmp/bcp/arh2.gz
test2=# select * from student2 limit 10;
 id |    fio
----+------------
  1 | 760308c5b0
  2 | 17cf96fea0
  3 | 3b8143c944
  4 | 4495df6c71
  5 | 85a183b7e6
  6 | 5892b44e0b
  7 | 5f2d139432
  8 | b8e5474a0b
  9 | 1bc746c7a1
 10 | dad56d1322
(10 rows)

test2=#
```
