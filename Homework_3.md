##Физичесский уровень PostgreSQL
###Создание и настройка VM
Я установил Oracle Virual Box, скачал образ Ubuntu 24.10 и установил ее на виртуальную машину. Псоел усновил на нее PostgreSQL 17  
```
daemom@MyOVM:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```

Далее создаем таблицу и наполняем ее данными:  
```
daemom@MyOVM:~$ sudo -u postgres psql
psql (17.3 (Ubuntu 17.3-1.pgdg24.10+1))
Type "help" for help.
postgres=# create table persons_vm(id serial, first_name text, second_name text);
CREATE TABLE
postgres=# insert into persons_vm(first_name, second_name) values('ivan', 'ivanov'); insert into persons_vm(first_name, second_name) values('petr', 'petrov');  insert into persons_vm(first_name, second_name) values('egor', 'egorov'); commit;
INSERT 0 1
INSERT 0 1
INSERT 0 1
WARNING:  there is no transaction in progress
COMMIT
```
Останавливаем кластер:  
```
daemom@MyOVM:/etc/postgresql/17/main$ sudo systemctl stop postgresql@17-main
daemom@MyOVM:/etc/postgresql/17/main$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 down   postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
Монтироуем дполнитеьный диск на VM:
