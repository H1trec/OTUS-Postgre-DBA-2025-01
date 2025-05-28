## Курсовая работа на тему: "Миграция БД с Oracle на PostgreSQL."

### Используемое ПО
* Oracle client
* БД Oracle
* Ora2Pg
* БД Postgres
* Perl
* Oracle VM
* Docker

### Установка и настройка БД Oracle

В связи с санкциями скачивание официальных дистрибутивов оказалось невозможным, мной был был найден выход: разворачивание БД Oracle в Docker из исходников для бесплатной версии 23.6.0. Однако дл того, чтобы исходники скачались и собрались пришлось использовать vpn. Без VPN постоянно была ошибка: ERROR: failed to solve: failed to load cache key: invalid response status 403.

#### Процесс сборки образа из исходников.
Файл buildContainerImage.sh был скачан из офциальных дистрибутивов Docker: https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance/dockerfiles/23.6.0
Для сборки конкретной версии используется параметр -v.   
```
daemom@OVMPG:/usr/src/dockerfiles$ sudo bash buildContainerImage.sh -f -v 23.6.0
Checking Docker version.
Containerfile.free
Ignored MD5 checksum.
==========================
Container runtime info:
Client: Docker Engine - Community
 Version:    28.1.1
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.23.0
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.35.1
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 28.1.1
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 05044ec0a9a75232cad458027ca83437aae3f4da
 runc version: v1.2.5-0-g59923ef
 init version: de40ad0
 Security Options:
  apparmor
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.11.0-25-generic
 Operating System: Ubuntu 24.10
 OSType: linux
 Architecture: x86_64
 CPUs: 2
 Total Memory: 7.255GiB
 Name: OVMPG
 ID: 187e3eac-fc3d-4559-966f-fc33cc1f0623
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
  ::1/128
  127.0.0.0/8
 Live Restore Enabled: false

==========================
Building image 'oracle/database:23.6.0-free' ...
[+] Building 1580.5s (18/18) FINISHED                                                                                                        docker:default
 => [internal] load build definition from Containerfile.free                                                                                           0.0s
 => => transferring dockerfile: 4.34kB                                                                                                                 0.0s
 => WARN: FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 21)                                                                        0.0s
 => [internal] load metadata for docker.io/library/oraclelinux:8                                                                                       1.7s
 => [internal] load .dockerignore                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                        0.0s
 => [internal] load build context                                                                                                                      0.1s
 => => transferring context: 353B                                                                                                                      0.0s
 => [builder 1/2] ADD https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23ai-1.0-1.el8.x86_64.rpm /install/              721.3s
 => CACHED [base 1/4] FROM docker.io/library/oraclelinux:8@sha256:0d48f4c6bad271da7abae47242e0478805343b81ecd1cec59523a6012d47eb72                     0.0s
 => [base 2/4] COPY checkSpace.sh oracle-free-23ai.conf setupLinuxEnv.sh runOracle.sh setPassword.sh checkDBStatus.sh createDB.sh runUserScripts.sh c  0.9s
 => [base 3/4] WORKDIR /install                                                                                                                        0.3s
 => [base 4/4] RUN mkdir -p "/opt/oracle" &&     mv "runOracle.sh" "setPassword.sh" "checkDBStatus.sh" "createDB.sh" "runUserScripts.sh" "configTcp  755.0s
 => [builder 1/2] ADD https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23ai-1.0-1.el8.x86_64.rpm /install/               20.2s
 => [builder 2/2] RUN unbuffer yum -y localinstall "/install/$(basename https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-fr  295.8s
 => [stage-2 1/6] COPY --chown=oracle:oinstall --from=builder /opt/oracle /opt/oracle                                                                190.0s
 => [stage-2 2/6] COPY --chown=oracle:oinstall --from=builder /etc/oratab /etc/oratab                                                                  0.9s
 => [stage-2 3/6] COPY --from=builder /etc/init.d/oracle-free-23ai /etc/init.d/oracle-free-23ai                                                        0.6s
 => [stage-2 4/6] COPY --from=builder /usr/share/doc/oracle-free-23ai/LICENSE /usr/share/doc/oracle-free-23ai/LICENSE                                  0.4s
 => [stage-2 5/6] RUN /opt/oracle/oraInventory/orainstRoot.sh &&     /opt/oracle/product/23ai/dbhomeFree/root.sh &&     echo 'export ORACLE_SID=FREE'  3.0s
 => [stage-2 6/6] WORKDIR /home/oracle                                                                                                                 0.8s
 => exporting to image                                                                                                                               176.1s
 => => exporting layers                                                                                                                              175.4s
 => => writing image sha256:05139b4f8749dfbf6cca4fd7f742e06a7149926242d4338069ea31b43040c14b                                                           0.0s
 => => naming to docker.io/oracle/database:23.6.0-free                                                                                                 0.0s

 2 warnings found (use docker --debug to expand):
 - FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 21)
 - UndefinedVar: Usage of undefined variable '$HOME' (line 38)


  Oracle Database container image for 'free' version 23.6.0 is ready to be extended:

    --> oracle/database:23.6.0-free

  Build completed in 1581 seconds.
```
#### Поднятие и настройка контейнера

Поднимаем контейнер с проброской порта 1521
```
daemom@OVMPG:~$ sudo docker run -p 1521:1521 oracle/database:23.6.0-free
Specify a password to be used for database accounts. Oracle recommends that the password entered should be at least 8 characters in length, contain at least 1 uppercase character, 1 lower case character and 1 digit [0-9]. Note that the same password will be used for SYS, SYSTEM and PDBADMIN accounts:
Confirm the password:
Configuring Oracle Listener.
Listener configuration succeeded.
Configuring Oracle Database FREE.
Enter SYS user password:
******************
Enter SYSTEM user password:
****************
Enter PDBADMIN User Password:
**************
Prepare for db operation
7% complete
Copying database files
29% complete
Creating and starting Oracle instance
30% complete
33% complete
36% complete
39% complete
43% complete
Completing Database Creation
47% complete
49% complete
50% complete
Creating Pluggable Databases
54% complete
71% complete
Executing Post Configuration Actions
93% complete
Running Custom Scripts
100% complete
Database creation complete. For details check the logfiles at:
 /opt/oracle/cfgtoollogs/dbca/FREE.
Database Information:
Global Database Name:FREE
System Identifier(SID):FREE
Look at the log file "/opt/oracle/cfgtoollogs/dbca/FREE/FREE.log" for further details.

Connect to Oracle Database using one of the connect strings:
     Pluggable database: 16de9588105a/FREEPDB1
     Multitenant container database: 16de9588105a

SQL*Plus: Release 23.0.0.0.0 - Production on Mon May 19 15:57:15 2025
Version 23.7.0.25.01

Copyright (c) 1982, 2025, Oracle.  All rights reserved.


Connected to:
Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.7.0.25.01

SQL>
System altered.

SQL>
Pluggable database altered.

SQL>
PL/SQL procedure successfully completed.

SQL> SQL>
Session altered.

SQL>
User created.

SQL>
Grant succeeded.

SQL>
Grant succeeded.

SQL>
Grant succeeded.

SQL>
User altered.

SQL> SQL> Disconnected from Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.7.0.25.01
The Oracle base remains unchanged with value /opt/oracle
The Oracle base remains unchanged with value /opt/oracle
#########################
DATABASE IS READY TO USE!
#########################
The following output is now a tail of the alert.log:
FREEPDB1(3):Tablespace created: USERS ts# 6
FREEPDB1(3):Completed: CREATE BIGFILE TABLESPACE "USERS" LOGGING  DATAFILE  '/opt/oracle/oradata/FREE/FREEPDB1/users01.dbf' SIZE 7M REUSE AUTOEXTEND ON NEXT  1280K MAXSIZE UNLIMITED  EXTENT MANAGEMENT LOCAL  SEGMENT SPACE MANAGEMENT  AUTO
FREEPDB1(3):ALTER DATABASE DEFAULT TABLESPACE "USERS"
FREEPDB1(3):Completed: ALTER DATABASE DEFAULT TABLESPACE "USERS"
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE
Completed: ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE
2025-05-19T15:57:15.494623+00:00
ALTER SYSTEM SET local_listener='' SCOPE=BOTH;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE
Completed: ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE
```

Для версии 23 SID всегда задается FREE. Для смены автоматически сгенерированного пароля пользователя sys необходимо скачать файл setPassword.sh и запустить его в контейнере, указав новый пароль:   
docker exec <container name> /u01/app/oracle/setPassword.sh <your password>

#### Создание БД для миграции

Для миграции была выбрана БД из примеров самого Oracle db-sample-schemas-23.3: https://github.com/oracle-samples/db-sample-schemas/releases/tag/v23.3

Развертывание БД осуществлается при помощи файла sh_install.sql, после его отработки:
```
Установка Simple DB

Installation 
-------------
Verification:

Table                        provided     actual
-------------------------- ---------- ----------
channels                            5          5
costs                           82112          0
countries                          35         35
customers                       55500          0
products                           72         72
promotions                        503          0
sales                          918843          0
times                            1826          0
supplementary_demographics       4500          0

Thank you!                                              
--------------------------------------------------------
The installation of the sample schema is now finished.
Please check the installation verification output above.
```
Видим, что импорт данных был выполнен не во все таблицы. Импортируем данные вручную, попутно решая проблему региональных настроек разделителей целой и дробной части: в файлах это ".", надо ",". С файлом sales.csv дополнительно пришлось решать проблемы лишних пробелов в конце строки.

### Установка и настройка ПО для миграции

Для выполнения миграции была выбрана утилита Ora2Pg. Дистрибутив можно скачать с официальнойй сттраницы проекта: https://github.com/darold/ora2pg/releases.   
Сначала я пытался развернуть всё необходимо для миграции ПО на той виртуальной машине где установлен Postgres и Docker с развернотой БД Oracle, однако постоянно возникали пробелмы с установкой модуля DBD::Oracle.   
В конце концов было принято решение развернуть ПО для миграции на локальной WIN машине.
Этапы установки:   
1. Устанавливаем клиенты Oracle:   
   * instantclient-basic-windows.x64-23.8.0.25.04   
   * instantclient-jdbc-windows.x64-23.8.0.25.04   
   * instantclient-sqlplus-windows.x64-23.8.0.25.04   
   * instantclient-tools-windows.x64-23.8.0.25.04   
   * instantclient-sdk-windows.x64-23.8.0.25.04   
Все скачивается с официальной страницы Oracle в виде zip архивов и распаковывается в одну директорию. Данную директорию необходимо потом  
 прописать в переменные окружения:   
* ORACLE_HOME   
* LD_LIBRARY_PATH   
* Path   
2. Устанавливаем Perl   
Я выбрал strawberry-perl-5.40.2.1-64bit   

3. Устанавливаем модули для работы с БД   
    * DBD::Oracle    
    * DBD::Pg  
Оба модуля уснавливаются через cpan командами install DBD::Oracle и install DBD::Pg   

4. Устанавливаем Ora2Pg   

Необходимо разархивировать скачанный дистрибутив в любую директорию (я выбрал D:\ora2pg).     
Выполнить команды Perl:   

*  perl C:\Ora2Pg\Makefile.PL   

*  gmake && gmake install   
Далее настраиваем ora2pg через конфигурационный файл ora2pg.conf.   

Настройка Oracle_HOME:   
ORACLE_HOME	D:\instantclient_23_8   

Путь к базе Oracle:   
ORACLE_DSN	dbi:Oracle:host=192.168.56.1;sid=FREE;port=1521   
ORACLE_USER	SH   
ORACLE_PWD	SH   
Настройки кодировки:   
NLS_LANG	AMERICAN_AMERICA.AL32UTF8   
CLIENT_ENCODING	UTF8   

Настройки подключения в БД PostgreSQL:   
PG_DSN		dbi:Pg:dbname=migrate;host=192.168.56.1;port=5432   
PG_USER	postgres   
PG_PWD		12345   

Настройки экспорта схемы:   

EXPORT_SCHEMA	1   
SCHEMA		SH   
CREATE_SCHEMA	1  
COMPILE_SCHEMA	1   

Отключение преобразования bitmap индексов в gin:   
BITMAP_AS_GIN		0   

### Миграция
1.  Миграция структуры
  Для начала посмотрим что у нас есть в схеме при помощи команды: ora2pg -t SHOW_REPORT
```
[2025-05-27 22:13:13] [========================>] 9/9 tables (100.0%) end of scanning.
[2025-05-27 22:13:19] [========================>] 11/11 objects types (100.0%) end of objects auditing.
-------------------------------------------------------------------------------
Ora2Pg v25.0 - Database Migration Report
-------------------------------------------------------------------------------
Version Oracle Database 23ai Free Release 23.0.0.0.0
Schema  SH
Size    1.56 MB

-------------------------------------------------------------------------------
Object  Number  Invalid Comments        Details
-------------------------------------------------------------------------------
DATABASE LINK   0       0       Database links will be exported as SQL/MED PostgreSQL's Foreign Data Wrapper (FDW) extensions using oracle_fdw.
DIMENSION       5       0
GLOBAL TEMPORARY TABLE  0       0       Global temporary table are not supported by PostgreSQL and will not be exported. You will have to rewrite some application code to match the PostgreSQL temporary table behavior.
INDEX   21      0       14 index(es) are concerned by the export, others are automatically generated and will do so on PostgreSQL. Bitmap will be exported as btree_gin index(es). Domain index are exported as b-tree but commented to be edited to mainly use FTS. Cluster, bitmap join and IOT indexes will not be exported at all. Reverse indexes are not exported too, you may use a trigram-based index (see pg_trgm) or a reverse() function based index and search. Use 'varchar_pattern_ops', 'text_pattern_ops' or 'bpchar_pattern_ops' operators in your indexes to improve search with the LIKE operator respectively into varchar, text or char columns.    11 bitmap index(es). 1 domain index(es). 2 b-tree index(es).
INDEX PARTITION 115     0       Only local indexes partition are exported, they are build on the column used for the partitioning.
JOB     0       0       Job are not exported. You may set external cron job with them.
MATERIALIZED VIEW       2       0       All materialized view will be exported as snapshot materialized views, they are only updated when fully refreshed.
SYNONYM 0       0       SYNONYMs will be exported as views. SYNONYMs do not exists with PostgreSQL but a common workaround is to use views or set the PostgreSQL search_path in your session to access object outside the current schema.
TABLE   9       0               Total number of rows: 112. Top 10 of tables sorted by number of rows:. products has 72 rows. countries has 35 rows. channels has 5 rows. Top 10 of largest tables:.
TABLE PARTITION 35      0       Partitions are well supported by PostgreSQL except key partition which will not be exported.    RANGE.
VIEW    1       0       Views are fully supported but can use specific functions.
-------------------------------------------------------------------------------
Total   188     0
-------------------------------------------------------------------------------
```
* Формируем скрипты для переноса структуры:
Таблицы:
```
ora2pg -b D:\ora2pg\data -t TABLE
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-27 22:17:51] [========================>] 9/9 tables (100.0%) end of scanning.
[2025-05-27 22:17:52] [========================>] 9/9 tables (100.0%) end of table export.
```
View:
```
ora2pg -b D:\ora2pg\data -t VIEW
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-27 22:52:01] [========================>] 1/1 views (100.0%) end of output.
```
MVIEW:
```
ora2pg -b D:\ora2pg\data -t MVIEW
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-27 22:55:46] [========================>] 2/2 materialized views (100.0%) end of output.
```
PARTITION:
```
ora2pg -b D:\ora2pg\data -t PARTITION
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-27 22:21:26] [========================>] 35/35 partitions (100.0%) end of output.
```
* Перенос структуры

Создаем в целевой БД Postgres польоавтеля SH и начинаем выполнять сформированные скрипты. Таблицы, патриции, view, mview. После выполнения всех скриптов получилась следующая БД:   
![SCHEMA](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/Project/schema.JPG?raw=true)   

* Перенос данных

При переное данных необхожимо учесть, что в таблицах есть FK и переносить необходимо в правильной последовательности.
Сначала переносим таблицы, в которых нет FK:
```
ora2pg -b D:\ora2pg\data -t COPY -a SUPPLEMENTARY_DEMOGRAPHICS,CHANNELS,COUNTRIES,PRODUCTS,TIMES,PROMOTIONS
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-28 20:52:12] [========================>] 6/6 tables (100.0%) end of scanning.

SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:33] [========================>] 5/5 rows (100.0%) Table CHANNELS (5 recs/sec)
[2025-05-28 20:52:33] [>                        ]    5/6941 total rows (0.1%) - (1 sec., avg: 5 recs/sec).
[2025-05-28 20:52:33] [>                        ]    5/6941 rows (0.1%) on total estimated data (1 sec., avg: 5 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:33] [========================>] 35/35 rows (100.0%) Table COUNTRIES (35 recs/sec)
[2025-05-28 20:52:33] [>                        ]   40/6941 total rows (0.6%) - (1 sec., avg: 40 recs/sec).
[2025-05-28 20:52:33] [>                        ]   40/6941 rows (0.6%) on total estimated data (1 sec., avg: 40 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:33] [========================>] 72/72 rows (100.0%) Table PRODUCTS (72 recs/sec)
[2025-05-28 20:52:33] [>                        ]  112/6941 total rows (1.6%) - (1 sec., avg: 112 recs/sec).
[2025-05-28 20:52:33] [>                        ]  112/6941 rows (1.6%) on total estimated data (1 sec., avg: 112 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:34] [========================>] 503/503 rows (100.0%) Table PROMOTIONS (503 recs/sec)
[2025-05-28 20:52:34] [==>                      ]  615/6941 total rows (8.9%) - (2 sec., avg: 307 recs/sec).
[2025-05-28 20:52:34] [==>                      ]  615/6941 rows (8.9%) on total estimated data (2 sec., avg: 307 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:35] [========================>] 4500/4500 rows (100.0%) Table SUPPLEMENTARY_DEMOGRAPHICS (4500 recs/sec)
[2025-05-28 20:52:35] [=================>       ] 5115/6941 total rows (73.7%) - (3 sec., avg: 1705 recs/sec).
[2025-05-28 20:52:35] [=================>       ] 5115/6941 rows (73.7%) on total estimated data (3 sec., avg: 1705 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:52:36] [========================>] 1826/1826 rows (100.0%) Table TIMES (1826 recs/sec)
[2025-05-28 20:52:36] [========================>] 6941/6941 total rows (100.0%) - (4 sec., avg: 1735 recs/sec).
[2025-05-28 20:52:36] [========================>] 6941/6941 rows (100.0%) on total estimated data (4 sec., avg: 1735 recs/sec)

Schema Export Complete
```
Затем перенсим таблицы с FK, обращая внимание на зависимости
```
ora2pg -b D:\ora2pg\data -t COPY -a CUSTOMERS,COSTS,SALES
HINT: you should activate USER_GRANTS for a connection without DBA privilege. Continuing with USER privilege.
[2025-05-28 20:55:25] [========================>] 3/3 tables (100.0%) end of scanning.

SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:55:51] [=>                       ]  3715/82112 rows (4.5%) Table COSTS_Q2_2021 (3715 recs/sec)
[2025-05-28 20:55:51] [>                        ]   3715/137612 total rows (2.7%) - (1 sec., avg: 3715 recs/sec).
[2025-05-28 20:55:52] [=>                       ]  4577/82112 rows (5.6%) Table COSTS_Q4_2019 (4577 recs/sec)
[2025-05-28 20:55:52] [=>                       ]   8292/137612 total rows (6.0%) - (2 sec., avg: 4146 recs/sec).
[2025-05-28 20:55:52] [=>                       ]  5884/82112 rows (7.2%) Table COSTS_Q1_2020 (5884 recs/sec)
[2025-05-28 20:55:52] [==>                      ]  14176/137612 total rows (10.3%) - (2 sec., avg: 7088 recs/sec).
[2025-05-28 20:55:53] [=>                       ]  4129/82112 rows (5.0%) Table COSTS_Q3_2019 (4129 recs/sec)
[2025-05-28 20:55:53] [===>                     ]  18305/137612 total rows (13.3%) - (3 sec., avg: 6101 recs/sec).
[2025-05-28 20:55:53] [>                        ]  2397/82112 rows (2.9%) Table COSTS_Q2_2019 (2397 recs/sec)
[2025-05-28 20:55:53] [===>                     ]  20702/137612 total rows (15.0%) - (3 sec., avg: 6900 recs/sec).
[2025-05-28 20:55:54] [=>                       ]  4411/82112 rows (5.4%) Table COSTS_Q1_2019 (4411 recs/sec)
[2025-05-28 20:55:54] [====>                    ]  25113/137612 total rows (18.2%) - (4 sec., avg: 6278 recs/sec).
[2025-05-28 20:55:54] [=>                       ]  4179/82112 rows (5.1%) Table COSTS_Q2_2020 (4179 recs/sec)
[2025-05-28 20:55:54] [=====>                   ]  29292/137612 total rows (21.3%) - (4 sec., avg: 7323 recs/sec).
[2025-05-28 20:55:55] [=>                       ]  4336/82112 rows (5.3%) Table COSTS_Q3_2020 (4336 recs/sec)
[2025-05-28 20:55:55] [=====>                   ]  33628/137612 total rows (24.4%) - (5 sec., avg: 6725 recs/sec).
[2025-05-28 20:55:55] [=>                       ]  5060/82112 rows (6.2%) Table COSTS_Q4_2020 (5060 recs/sec)
[2025-05-28 20:55:55] [======>                  ]  38688/137612 total rows (28.1%) - (5 sec., avg: 7737 recs/sec).
[2025-05-28 20:55:56] [=>                       ]  3772/82112 rows (4.6%) Table COSTS_Q1_2021 (3772 recs/sec)
[2025-05-28 20:55:56] [=======>                 ]  42460/137612 total rows (30.9%) - (6 sec., avg: 7076 recs/sec).
[2025-05-28 20:55:57] [==>                      ]  7328/82112 rows (8.9%) Table COSTS_Q1_2022 (7328 recs/sec)
[2025-05-28 20:55:57] [========>                ]  49788/137612 total rows (36.2%) - (7 sec., avg: 7112 recs/sec).
[2025-05-28 20:55:57] [=>                       ]  5088/82112 rows (6.2%) Table COSTS_Q4_2021 (5088 recs/sec)
[2025-05-28 20:55:57] [=========>               ]  54876/137612 total rows (39.9%) - (7 sec., avg: 7839 recs/sec).
[2025-05-28 20:55:58] [=>                       ]  4798/82112 rows (5.8%) Table COSTS_Q3_2021 (4798 recs/sec)
[2025-05-28 20:55:58] [==========>              ]  59674/137612 total rows (43.4%) - (8 sec., avg: 7459 recs/sec).
[2025-05-28 20:55:59] [=>                       ]  5882/82112 rows (7.2%) Table COSTS_Q2_2022 (5882 recs/sec)
[2025-05-28 20:55:59] [===========>             ]  65556/137612 total rows (47.6%) - (9 sec., avg: 7284 recs/sec).
[2025-05-28 20:55:59] [==>                      ]  7545/82112 rows (9.2%) Table COSTS_Q3_2022 (7545 recs/sec)
[2025-05-28 20:55:59] [============>            ]  73101/137612 total rows (53.1%) - (9 sec., avg: 8122 recs/sec).
[2025-05-28 20:56:01] [==>                      ]  9011/82112 rows (11.0%) Table COSTS_Q4_2022 (4505 recs/sec)
[2025-05-28 20:56:01] [==============>          ]  82112/137612 total rows (59.7%) - (11 sec., avg: 7464 recs/sec).
[2025-05-28 20:56:01] [>                        ]     0/82112 rows (0.0%) Table COSTS_Q1_2023 (0 recs/sec)
[2025-05-28 20:56:01] [==============>          ]  82112/137612 total rows (59.7%) - (11 sec., avg: 7464 recs/sec).
[2025-05-28 20:56:01] [>                        ]     0/82112 rows (0.0%) Table COSTS_Q2_2023 (0 recs/sec)
[2025-05-28 20:56:01] [==============>          ]  82112/137612 total rows (59.7%) - (11 sec., avg: 7464 recs/sec).
[2025-05-28 20:56:01] [>                        ]     0/82112 rows (0.0%) Table COSTS_Q3_2023 (0 recs/sec)
[2025-05-28 20:56:01] [==============>          ]  82112/137612 total rows (59.7%) - (11 sec., avg: 7464 recs/sec).
[2025-05-28 20:56:01] [>                        ]     0/82112 rows (0.0%) Table COSTS_Q4_2023 (0 recs/sec)
[2025-05-28 20:56:01] [==============>          ]  82112/137612 total rows (59.7%) - (11 sec., avg: 7464 recs/sec).
[2025-05-28 20:56:01] [==============>          ]  82112/137612 rows (59.7%) on total estimated data (11 sec., avg: 7464 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:56:14] [========================>] 55500/55500 rows (100.0%) Table CUSTOMERS (4269 recs/sec)
[2025-05-28 20:56:14] [========================>] 137612/137612 total rows (100.0%) - (24 sec., avg: 5733 recs/sec).
[2025-05-28 20:56:14] [========================>] 137612/137612 rows (100.0%) on total estimated data (24 sec., avg: 5733 recs/sec)
SET client_encoding TO 'UTF8';
SET synchronous_commit TO off;
SET search_path = sh,public;

[2025-05-28 20:56:15] [========================>] 0/0 rows (100.0%) Table SALES_2018 (0 recs/sec)
[2025-05-28 20:56:15] [========================>] 137612/137612 total rows (100.0%) - (25 sec., avg: 5504 recs/sec).
[2025-05-28 20:56:25] [========================>] 79445/0 rows (100.0%) Table SALES_H1_2019 (7944 recs/sec)
[2025-05-28 20:56:25] [========================>] 217057/137612 total rows (157.7%) - (35 sec., avg: 6201 recs/sec).
[2025-05-28 20:56:39] [========================>] 99389/0 rows (100.0%) Table SALES_H2_2019 (7099 recs/sec)
[2025-05-28 20:56:39] [========================>] 316446/137612 total rows (230.0%) - (49 sec., avg: 6458 recs/sec).
[2025-05-28 20:56:48] [========================>] 64186/0 rows (100.0%) Table SALES_Q1_2020 (7131 recs/sec)
[2025-05-28 20:56:48] [========================>] 380632/137612 total rows (276.6%) - (58 sec., avg: 6562 recs/sec).
[2025-05-28 20:56:57] [========================>] 62388/0 rows (100.0%) Table SALES_Q4_2020 (6932 recs/sec)
[2025-05-28 20:56:57] [========================>] 443020/137612 total rows (321.9%) - (67 sec., avg: 6612 recs/sec).
[2025-05-28 20:57:06] [========================>] 62197/0 rows (100.0%) Table SALES_Q1_2021 (6910 recs/sec)
[2025-05-28 20:57:06] [========================>] 505217/137612 total rows (367.1%) - (76 sec., avg: 6647 recs/sec).
[2025-05-28 20:57:13] [========================>] 55515/0 rows (100.0%) Table SALES_Q2_2021 (7930 recs/sec)
[2025-05-28 20:57:13] [========================>] 560732/137612 total rows (407.5%) - (83 sec., avg: 6755 recs/sec).
[2025-05-28 20:57:22] [========================>] 58950/0 rows (100.0%) Table SALES_Q3_2021 (6550 recs/sec)
[2025-05-28 20:57:22] [========================>] 619682/137612 total rows (450.3%) - (92 sec., avg: 6735 recs/sec).
[2025-05-28 20:57:29] [========================>] 55984/0 rows (100.0%) Table SALES_Q4_2021 (7997 recs/sec)
[2025-05-28 20:57:29] [========================>] 675666/137612 total rows (491.0%) - (99 sec., avg: 6824 recs/sec).
[2025-05-28 20:57:38] [========================>] 60608/0 rows (100.0%) Table SALES_Q1_2022 (6734 recs/sec)
[2025-05-28 20:57:38] [========================>] 736274/137612 total rows (535.0%) - (108 sec., avg: 6817 recs/sec).
[2025-05-28 20:57:46] [========================>] 63292/0 rows (100.0%) Table SALES_Q2_2022 (7911 recs/sec)
[2025-05-28 20:57:46] [========================>] 799566/137612 total rows (581.0%) - (116 sec., avg: 6892 recs/sec).
[2025-05-28 20:57:55] [========================>] 65769/0 rows (100.0%) Table SALES_Q3_2022 (7307 recs/sec)
[2025-05-28 20:57:55] [========================>] 865335/137612 total rows (628.8%) - (125 sec., avg: 6922 recs/sec).
[2025-05-28 20:58:05] [========================>] 69749/0 rows (100.0%) Table SALES_Q4_2022 (6974 recs/sec)
[2025-05-28 20:58:05] [========================>] 935084/137612 total rows (679.5%) - (135 sec., avg: 6926 recs/sec).
[2025-05-28 20:58:13] [========================>] 54233/0 rows (100.0%) Table SALES_Q2_2020 (6779 recs/sec)
[2025-05-28 20:58:13] [========================>] 989317/137612 total rows (718.9%) - (143 sec., avg: 6918 recs/sec).
[2025-05-28 20:58:22] [========================>] 67138/0 rows (100.0%) Table SALES_Q3_2020 (7459 recs/sec)
[2025-05-28 20:58:22] [========================>] 1056455/137612 total rows (767.7%) - (152 sec., avg: 6950 recs/sec).
[2025-05-28 20:58:22] [========================>] 137612/137612 rows (100.0%) on total estimated data (152 sec., avg: 905 recs/sec)

Schema Export Complete
```
Проверяем, что данные залились   
![COSTS](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/Project/cost.JPG?raw=true)   
![CHANNELS](https://github.com/H1trec/OTUS-Postgre-DBA-2025-01//blob/main/Project/CH.JPG?raw=true) 

### Вместо вывода

В итоге при помощи гугла и статьи на Хабре, мне удаалось выполнить миграцию небольшой БД Oracle без переноса PL/SQL кода. Сам процесс миграции занал не лишком большое время, больше времени было потрачено на отладку и исправление возникающих ошибок, которых было довольно много- это и ошбки при начальном развертываниии на VM Ubuntu, затем ошибки при установке всех моудлей уже на win средеб затем ошибки при миграции результатом, которых стала описанная конфигурация ora2pg  и этапы самой миграции.


### Используемые ресурсы
* Дистрибутивы docker oracle: https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance   
* Дисрибутив БД Oracle,с данными: https://github.com/oracle-samples/db-sample-schemas/releases/tag/v23.3   
* Документация по Ora2Pg: https://ora2pg.darold.net/documentation.html   
* Вспомогателная статья на Хабр: https://habr.com/ru/companies/sigma/articles/669874/
* Дистибутивы Oracle client: https://www.oracle.com/database/technologies/instant-client/downloads.html   
* Дистрибутивы perl: https://strawberryperl.com/
