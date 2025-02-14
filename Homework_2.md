##Установка и настройка PostgteSQL в контейнере Docker  
###Установка Docker
```
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 sudo apt install docker-ce -y
```
###Установка PostgteSQL

Создаем сеть:  
```
sudo docker network create pg-net
```
Устаналавливаем PostgteSQL
```
sudo docker run --name pg_server --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5430:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:17
```
Где:  
POSTGRES_PASSWORD- пароль для пользователя postgres  
-p 5430:5432 - пробрасывание портов(на моей машине уже был занят порт 5432 локальным инстансом PostgteSQL)  
postgres:17- версия устанавливаемого PostgteSQL  
pg_server - название контейнера  
Проверяем, что установилось и работает:  
```
daemom@WIN-I0O5TP50MV7:/usr/src$ sudo docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS                                         NAMES
1565b3468321   postgres:17   "docker-entrypoint.s…"   3 minutes ago   Up 3 minutes   0.0.0.0:5430->5432/tcp, [::]:5430->5432/tcp   pg_server
```
При попытке подключения полчучаем ошибку:  
```
psql: error: connection to server at "pg_server" (172.19.0.2), port 5432 failed: FATAL:  password authentication failed for user "postgres"
```
Идем править настройки:
pg_hba.conf:
```
password_encryption = scram-sha-256
host    all             all             0.0.0.0/0               scram-sha-256 
```
postgresql.conf:  
```
listen_addresses = '*'
```
Перезагружаем инстанс:  
```
sudo docker stop pg_server
sudo docker start pg_server
```
Заходим в контейнер и подключаемся к БД:
```
daemom@WIN-I0O5TP50MV7:/usr/src$ sudo docker exec -it pg_server bash
root@1565b3468321:/# sudo -u postgres psql
```
Меняем пароль для пользователя postgres:  
```
postgres=# \password
Enter new password for user "postgres":
Enter it again:
```
Создаем БД
```
postgres=# CREATE DATABASE dockerdb OWNER postgres;
```

Запускаем контейнер с клиентом:
```
daemom@WIN-I0O5TP50MV7:/usr/src$ sudo docker run -it --rm --network pg-net --name pg-client postgres:17 psql -h pg_server -U postgres -d dockerdb
Password for user postgres:
psql (17.3 (Debian 17.3-1.pgdg120+1))
Type "help" for help.
```

Создаем таблицу и вставляем данные:  
```
dockerdb=# create table docker_persons(id serial, first_name text, second_name text);
CREATE TABLE
dockerdb=# insert into docker_persons(first_name, second_name) values('ivan', 'ivanov'); insert into docker_persons(first_name, second_name) values('petr', 'petrov');  insert into docker_persons(first_name, second_name) values('egor', 'egorov'); commit;
INSERT 0 1
INSERT 0 1
INSERT 0 1
```

Подключаемся с локально установленного на ПК PGAdmin и проверяем наличие данных:
![PGADMIN](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/PGadmin.JPG?raw=true)  

Удаляем контйнер с сервером:
```
daemom@WIN-I0O5TP50MV7:~$ sudo docker stop pg_server
pg_server
daemom@WIN-I0O5TP50MV7:~$ sudo docker rm pg_server
pg_server
```
Создаем контейнер с сервером снова:
```
daemom@WIN-I0O5TP50MV7:~$ sudo docker run --name pg_server --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5430:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:17
fb7fa2c819a5aa52b1f41f2dbfa52a1301838c8b8f4cfcc4c124f025b7f768a0
```
Подключаемся к контейнеру через клиентский контейнер:
```
daemom@WIN-I0O5TP50MV7:~$ sudo docker run -it --rm --network pg-net --name pg-client postgres:17 psql -h pg_server -U postgres -d dockerdb
Password for user postgres:
psql (17.3 (Debian 17.3-1.pgdg120+1))
Type "help" for help.
```
Проверяем наличие данных:
```
dockerdb=# select * from docker_persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | egor       | egorov
(3 rows)

dockerdb=#
```
