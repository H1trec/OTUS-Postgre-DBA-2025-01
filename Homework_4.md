###Логический уровень PostgreSQL
##Устновка PostgreSQL14 и проверка, что кластер работает.
```
daemom@MyVM2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```
##Устанавливаем пароль для пользователя postgres:
```
daemom@MyVM2:~$ sudo -u postgres psql
postgres=# alter user postgres password '12345';
ALTER ROLE
```
##Создаем новую БД и заходим в нее:  
```
postgres=# create database testdb;
CREATE DATABASE
postgres=# \c testdb
You are now connected to database "testdb" as user "postgres".
testdb=#
```
