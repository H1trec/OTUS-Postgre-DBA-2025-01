## Уровни изоляций транзакций в PostgreSQL
### Установка PostgreSQL
Я установил PostgreSQL на локальный ПК в WSL Ubuntu  
```
daemom@WIN-I0O5TP50MV7:~$ sudo systemctl status postgresql@17-main.service  
● postgresql@17-main.service - PostgreSQL Cluster 17-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: active (running) since Thu 2025-02-06 21:09:35 MSK; 46s ago
    Process: 4331 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 17-main start (code=exited, status=0/SUCCE>   Main PID: 4336 (postgres)
      Tasks: 6 (limit: 19065)
     Memory: 19.2M
     CGroup: /system.slice/system-postgresql.slice/postgresql@17-main.service
             ├─4336 /usr/lib/postgresql/17/bin/postgres -D /var/lib/postgresql/17/main -c config_file=/etc/postgresql/1>
              ├─4337 "postgres: 17/main: checkpointer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                ├─4338 "postgres: 17/main: background writer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                  ├─4340 "postgres: 17/main: walwriter " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                    ├─4341 "postgres: 17/main: autovacuum launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
                      └─4342 "postgres: 17/main: logical replication launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
Feb 06 21:09:32 WIN-I0O5TP50MV7 systemd[1]: Starting PostgreSQL Cluster 17-main...
Feb 06 21:09:35 WIN-I0O5TP50MV7 systemd[1]: Started PostgreSQL Cluster 17-main.
```
Завел нового пользователя и создал БД:  
```
daemom@WIN-I0O5TP50MV7:~$ sudo -i -u postgres
postgres@WIN-I0O5TP50MV7:~$ createuser --interactive
Enter name of role to add: daemom
Shall the new role be a superuser? (y/n) y
postgres@WIN-I0O5TP50MV7:~$ createdb daemom
```
### Работа с уровнями изоляций
1. Выключаем auto commit:
```
daemom=# \set AUTOCOMMIT off
daemom=# \echo :AUTOCOMMIT
```
2. В первой сессии создам таблицу и наполняем ее данными:
```
daemom=#  create table persons(id serial, first_name text, second_name text);
CREATE TABLE
daemom=*# insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
INSERT 0 1
INSERT 0 1
COMMIT
```
3. Проверяем уровень изоляции:
```
daemom=# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 read committed
(1 row)
```
4. Начинаем новые транзакции:
```
daemom=# begin;
BEGIN
```
5. Добавляем новые данные в первой сессии:
```
daemom=*#  insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1
```
6. Выполняем запрос во второй сессии:
```
daemom=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
```  
Новой записи нет из-за того, что мы не закоммитили в первой сессии вставку строки, а уровень изоляции у нас read committed.  

7. Завершаем первую транзакцию:  
```
daemom=*# commit;
COMMIT
```
8. Выполняем запрос во второй сессии:
```
  daemom=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
 ```
  Новая запись появилась потому, что мы закоммитили изменения и запись стала доступна для чтения поскольку уровень изоляции у нас read committed.

9. Начинаем новые транзакции с repeatable read уровнем изоляции:
```
daemom=# BEGIN isolation level repeatable read;
BEGIN
```
10. Добавляем данные в первой сессии:
```
daemom=*#  insert into persons(first_name, second_name) values('sveta', 'svetova');
INSERT 0 1
```
11. Выполняем запрос во второй сессии:
```
  daemom=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```
Новой записи нет из-за того, что мы используем уровень изоляции repeatable read и нам не видны изменения данных из первой сессии.  

12. Завершаем первую транзакцию:
```
daemom=*# commit;
COMMIT
```
13. Выполняем запрос во второй сессии:
``` 
daemom=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
``` 
Нам до сих пор не доступны данные из первой сессии, поскольку мы находимся внтури своей сессии с уровенем изоляции repeatable read.  

14. Завершаем вторую транзацию:
``` 
daemom=*# commit;
COMMIT
```
15. Выполняем запрос во второй сессии:
```
daemom=# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
```
Мы видим 4 строки поскольку мы закончили свою транзакцию и нам теперь "видны" все изменения из первой сессии.
