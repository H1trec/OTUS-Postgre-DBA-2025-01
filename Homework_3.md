## Физичесский уровень PostgreSQL
### Создание и настройка VM
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
Монтироуем дополнитеьный диск на VM:
![NEWVOLUME](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/New_Volume.JPG?raw=true)    

Переносим даные:
```
daemom@MyOVM:/media/daemom$ sudo chown -R postgres:postgres /media/daemom/D
daemom@MyOVM:/media/daemom$ sudo mv /var/lib/postgresql/17 /media/daemom/D
```
При попытке запуска кластер не стартует поскольку мы перенесли все данные в другое место, чтобы это справить необходимо поправить файл конфигурации /etc/postgresql/17/main/postgresql.conf:
```
data_directory = '/media/daemom/D/17/main'
```
Дополнительно останавливаем сервис:
```
sudo pkill -u postgres
daemom@MyOVM:~$ ps -u postgres
    PID TTY          TIME CMD
```
Запускаем кластер:
```
daemom@MyOVM:/usr/lib/postgresql/17/bin$ sudo -u postgres pg_ctlcluster 17 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@17-main
Cluster is already running.
```
Подключаемс и проверяем наличие данных:
```
daemom@MyOVM:/usr/lib/postgresql/17/bin$ sudo -u postgres psql
psql (17.3 (Ubuntu 17.3-1.pgdg24.10+1))
Type "help" for help.

postgres=# select * from persons_vm;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | egor       | egorov
(3 rows)
```
### Задание со *
Создал вторую VM, так установил на нее  Ubuntu 24.10 и  PostgreSQL 17 : 
```
daemom@MyOVM2:~$ sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
Затем на первой VM остовил кластер и сервисы PostgreSQL:
```
daemom@MyOVM:/usr/lib/postgresql/17/bin$ sudo pg_ctlcluster 17 main stop
daemom@MyOVM:/usr/lib/postgresql/17/bin$ sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory          Log file
17  main    5432 down   postgres /media/daemom/D/17/main /var/log/postgresql/postgresql-17-main.log
```
Затем через GUI интрерфейс отмонтировал дополнительный диск, остановил обе VM, примонтировал диск ко второй VM и запустил ее.  
Затем останавливаем кластер и сервисы:
```
daemom@MyOVM2:~$ sudo pg_ctlcluster 17 main stop
daemom@MyOVM2:~$ sudo pkill -u postgres
daemom@MyOVM2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 down   postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
Удалаем каталог:
```
daemom@MyOVM2:~$ sudo rm -R /var/lib/postgresql/17
```
правим снова конфигурационный файл /etc/postgresql/17/main/postgresql.conf и высталяем права на каталог:
```
правки в файле:data_directory = '/media/daemom/D/17/main'

sudo chown -R postgres:postgres /media/daemom/D
sudo chmod -R 777 /media/daemom
```
Запускаем кластер:
```
daemom@MyOVM2:~$ sudo -u postgres pg_ctlcluster 17 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@17-main
daemom@MyOVM2:~$ sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory          Log file
17  main    5432 online postgres /media/daemom/D/17/main /var/log/postgresql/postgresql-17-main.log
```

Странно, но только при выставлнении прав : sudo chmod -R 777 /media/daemom кластер смог подняться как в первом, так и во втором случае. Прав вида sudo chmod -R u+rwx,g-rwx,o-rwx '/media/daemom/D' не хватало.



