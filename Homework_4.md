## Логический уровень PostgreSQL
### Устновка PostgreSQL14 и проверка, что кластер работает.
```
daemom@MyVM2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```
### Устанавливаем пароль для пользователя postgres:
```
daemom@MyVM2:~$ sudo -u postgres psql
postgres=# alter user postgres password '12345';
ALTER ROLE
```
### Создаем новую БД и заходим в нее:  
```
postgres=# create database testdb;
CREATE DATABASE
postgres=# \c testdb
You are now connected to database "testdb" as user "postgres".
testdb=#
```
### Создаем схему, таблицу и вставляем в нее данные:
```
testdb=# CREATE SCHEMA test_schema;
CREATE SCHEMA
testdb=# CREATE TABLE test_tbl(col1 integer);
CREATE TABLE
testdb=#  INSERT INTO test_tbl values(1);
INSERT 0 1
testdb=#
```
### Создаем роль и раздаем ей GRANT'ы:
```
testdb=# CREATE role readonly;
CREATE ROLE
testdb=# grant connect on DATABASE testdb TO readonly;
GRANT
testdb=# grant usage on SCHEMA test_schema to readonly;
GRANT
testdb=# grant SELECT on all TABLEs in SCHEMA test_schema TO readonly;
GRANT
testdb=#
```
### Создаем пользователя и назначаем ему роль:  
```
testdb=# CREATE USER testread with password 'test123';
CREATE ROLE
testdb=# grant readonly TO testread;
GRANT ROLE
testdb=#
```
### Правим файл pg_hba.conf и перезапускаем кластер:  
```
# "local" is for Unix domain socket connections only
local   all             all                                     md5
```
```
daemom@MyVM2:~$ sudo systemctl restart postgresql@14-main
```
### Заходим под пользователем в БД и выполняем селект:  
```
testdb-# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
testdb->
testdb=>  select * from test_tbl;
ERROR:  permission denied for table test_tbl
testdb=> \dt
          List of relations
 Schema |   Name   | Type  |  Owner
--------+----------+-------+----------
 public | test_tbl | table | postgres
(1 row)
```
Доступа к таблице нет потому, что она создана в схеме public(по-умолчанию), а прав на схему public у польователя нет.

### Пересоздаем таблицу в нужной схеме, вставляем данные и пыатемся прочитать данные:

```
testdb=> \c testdb postgres
You are now connected to database "testdb" as user "postgres".
testdb=# DROP TABLE test_tbl;
DROP TABLE
testdb=# CREATE TABLE test_schema.test_tbl(col1 integer);
CREATE TABLE
testdb=# INSERT INTO test_schema.test_tbl values(1);
INSERT 0 1
testdb=# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
testdb=> select * from test_schema.test_tbl;
ERROR:  permission denied for table test_tbl
```
Получаем ошибку доступа потому, что изначально мы давали GRANT на селект всех существующих таблиц, но он не распространяется на вновь созданные таблицы, для того, чтобы это исправить нужно выдать GRANT немного по-другому:
Сначала выдаем права на select снова, поскольку таблица наша пересозлавалсь
```
grant SELECT on all TABLEs in SCHEMA test_schema TO readonly;
```
Затем уже устанавливаем привилегию по-умолчанию:
```
testdb=# ALTER default privileges in SCHEMA test_schema grant SELECT on TABLES to readonly;
ALTER DEFAULT PRIVILEGES
```
Проверяем:  
```
testdb=# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
testdb=> select * from test_schema.test_tbl;
 col1
------
    1
(1 row)

testdb=>
```
## Пытаемся создать таблицу и вставить данные под пользователем testread:
```
testdb=> create table test_tbl2(c1 integer); insert into test_tbl2 values (2);
CREATE TABLE
INSERT 0 1
testdb=>
```
Команда отработала успешно, поскольку таблица по-умолчанию создалась в схеме public:
```
testdb=> \dt
           List of relations
 Schema |   Name    | Type  |  Owner
--------+-----------+-------+----------
 public | test_tbl2 | table | testread
(1 row)
```

Для того, чтобы пользователь не смог созадвать и изменять данные в схеме Public необходимо отозвать у него права через команду REVOKE под пользователем postgres:
```
testdb=> \c testdb postgres;
You are now connected to database "testdb" as user "postgres".
testdb=# REVOKE CREATE on SCHEMA public FROM public;
REVOKE
testdb=# REVOKE ALL  PRIVILEGES on DATABASE testdb FROM public;
REVOKE
testdb=#
```
## Выполняем команды:
```
testdb=> create table test_tbl3(c1 integer); 
ERROR:  permission denied for schema public
LINE 1: create table test_tbl3(c1 integer);
```
Поскольук мы забрали привелегии, новые таблицы создавать уже не получится.

```
testdb=> insert into test_tbl2 values (4);
INSERT 0 1
```

Данные вставились, поскольку для того, чтобы это запретить нужно отозвать права на INSERT на таблицу:
```
testdb=> \c testdb postgres;
You are now connected to database "testdb" as user "postgres".
testdb=# REVOKE INSERT on test_tbl2 from testread;
REVOKE
testdb=# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
```
Тепер при попытке вставить данные будет ошибка:
```
testdb=> insert into test_tbl2 values (5);
ERROR:  permission denied for table test_tbl2
```
