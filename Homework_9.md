## Работа с индексами
### Создание простого индекса
#### Подготовка
Создаем БД: 
```
postgres=# CREATE DATABASE test_indexes;
CREATE DATABASE
```
Создаем и заполняем таблицу:  
```
postgres=# \c test_indexes;
You are now connected to database "test_indexes" as user "postgres".
test_indexes=# CREATE TABLE products(
test_indexes(#     product_id   integer,
test_indexes(#     brand        char(1),
test_indexes(#     gender       char(1),
test_indexes(#     price        integer,
test_indexes(#     is_available boolean
test_indexes(# );
CREATE TABLE
test_indexes=# WITH random_data AS (
test_indexes(#     SELECT
test_indexes(#     num,
test_indexes(#     random() AS rand1,
test_indexes(#     random() AS rand2,
test_indexes(#     random() AS rand3
test_indexes(#     FROM generate_series(1, 10000000) AS s(num)
test_indexes(# )
test_indexes-# INSERT INTO products
test_indexes-#     (product_id, brand, gender, price, is_available)
test_indexes-# SELECT
test_indexes-#     random_data.num,
test_indexes-#     chr((32 + random_data.rand1 * 94)::integer),
test_indexes-#     case when random_data.num % 2 = 0 then 'М' else 'Ж' end,
test_indexes-#     (random_data.rand2 * 100)::integer,
test_indexes-#     random_data.rand3 < 0.01
test_indexes-#     FROM random_data
test_indexes-#     ORDER BY random();
INSERT 0 10000000
```
#### Работа с простым индексом:  
Смотрим на план до создания индекса:
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id = 1878;
                                   QUERY PLAN
---------------------------------------------------------------------------------
 Gather  (cost=1000.00..116779.03 rows=1 width=14)
   Workers Planned: 2
   ->  Parallel Seq Scan on products  (cost=0.00..115778.93 rows=1 width=14)
         Filter: (product_id = 1878)
 JIT:
   Functions: 2
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(7 rows)
```
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id < 10088;
                                   QUERY PLAN
---------------------------------------------------------------------------------
 Gather  (cost=1000.00..117874.03 rows=10951 width=14)
   Workers Planned: 2
   ->  Parallel Seq Scan on products  (cost=0.00..115778.93 rows=4563 width=14)
         Filter: (product_id < 10088)
 JIT:
   Functions: 2
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(7 rows)
```
Видим, что в обоихх случаях идет последовательное сканирование таблицы: Seq Scan on products  
Создаем индекс: 
```
test_indexes=# CREATE INDEX
test_indexes-#     idx_products_product_id
test_indexes-#     ON products(product_id);
```
Смотрим план: 
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id = 1878;
                                       QUERY PLAN
-----------------------------------------------------------------------------------------
 Index Scan using idx_products_product_id on products  (cost=0.43..8.45 rows=1 width=14)
   Index Cond: (product_id = 1878)
(2 rows)
```
```
test_indexes=# EXPLAIN
SELECT * FROM products
    WHERE product_id < 10088;
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=223.20..30068.98 rows=11711 width=14)
   Recheck Cond: (product_id < 10088)
   ->  Bitmap Index Scan on idx_products_product_id  (cost=0.00..220.27 rows=11711 width=0)
         Index Cond: (product_id < 10088)
(4 rows)
```

Видим теперь, что для первого случая идет Index Scanа во втором случае сначала идет Bitmap Index Scan, для поиска адрес строк, а уже потом идет Bitmap Heap Scan для получения нужных строк с результатом поиска.
B-tree индексы дают ускорение при поиске данных, которые можно отсортировать.

#### Работа с полнотекстовым поиском: 
Создаем таблицу:  
```
CREATE TABLE documents (
    title    varchar(64),
    metadata jsonb,
    contents text
);
```
Вставляем данные:  
```
test_indexes=# INSERT INTO documents
test_indexes-#     (title, metadata, contents)
test_indexes-# VALUES
test_indexes-#     ( 'Document 1',
test_indexes(#       '{"author": "John",  "tags": ["legal", "real estate"]}',
test_indexes(#       'This is a legal document about real estate.' ),
test_indexes-#     ( 'Document 2',
test_indexes(#       '{"author": "Jane",  "tags": ["finance", "legal"]}',
test_indexes(#       'Financial statements should be verified.' ),
test_indexes-#     ( 'Document 3',
test_indexes(#       '{"author": "Paul",  "tags": ["health", "nutrition"]}',
test_indexes(#       'Regular exercise promotes better health.' ),
test_indexes-#     ( 'Document 4',
test_indexes(#       '{"author": "Alice", "tags": ["travel", "adventure"]}',
test_indexes(#       'Mountaineering requires careful preparation.' ),
test_indexes-#     ( 'Document 5',
test_indexes(#       '{"author": "Bob",   "tags": ["legal", "contracts"]}',
test_indexes(#       'Contracts are binding legal documents.' ),
test_indexes-#     ( 'Document 6',
test_indexes(#        '{"author": "Eve",  "tags": ["legal", "family law"]}',
test_indexes(#        'Family law addresses diverse issues.' ),
test_indexes-#     ( 'Document 7',
test_indexes(#       '{"author": "John",  "tags": ["technology", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 8',
test_indexes(#       '{"author": "John",  "tags": ["technology", "contracts"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 9',
test_indexes(#       '{"author": "Bob",  "tags": ["legal", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 10',
test_indexes(#       '{"author": "John",  "tags": ["finance", "family law"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 11',
test_indexes(#       '{"author": "John",  "tags": ["technology", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 12',
test_indexes(#       '{"author": "Paul",  "tags": ["legal", "family law"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 13',
test_indexes(#       '{"author": "Eve",  "tags": ["technology", "contracts"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 14',
test_indexes(#       '{"author": "Bob",  "tags": ["legal", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 15',
test_indexes(#       '{"author": "John",  "tags": ["finance", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 16',
test_indexes(#       '{"author": "Eve",  "tags": ["legal", "contracts"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 17',
test_indexes(#       '{"author": "Bob",  "tags": ["technology", "family law"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 18',
test_indexes(#       '{"author": "Bob",  "tags": ["technology", "contracts"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 19',
test_indexes(#       '{"author": "John",  "tags": ["legal", "family law"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 20',
test_indexes(#       '{"author": "Eve",  "tags": ["finance", "contracts"]}',
test_indexes(#       'Tech innovations are changing the world.' ),
test_indexes-# ( 'Document 21',
test_indexes(#       '{"author": "Bob",  "tags": ["legal", "innovation"]}',
test_indexes(#       'Tech innovations are changing the world.' );
INSERT 0 21
```

Смотрим план с полнотекстовым поиском:
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM documents
test_indexes-#     WHERE contents like '%document%';
                         QUERY PLAN
------------------------------------------------------------
 Seq Scan on documents  (cost=0.00..14.25 rows=1 width=210)
   Filter: (contents ~~ '%document%'::text)
(2 rows)

```
Создаем GIN-индекс:  
```
test_indexes=# CREATE INDEX
test_indexes-#     idx_documents_contents
test_indexes-#     ON documents
test_indexes-#     USING GIN(to_tsvector('english', contents));
CREATE INDEX
```
Смотрим план:
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM documents
test_indexes-#     WHERE to_tsvector('english', contents) @@ 'document';
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Bitmap Heap Scan on documents  (cost=8.00..12.26 rows=1 width=210)
   Recheck Cond: (to_tsvector('english'::regconfig, contents) @@ '''document'''::tsquery)
   ->  Bitmap Index Scan on idx_documents_contents  (cost=0.00..8.00 rows=1 width=0)
         Index Cond: (to_tsvector('english'::regconfig, contents) @@ '''document'''::tsquery)
(4 rows)
```
Видим, что до создания индекса при запросе происходило полное сканирование таблицы, после создани индекса сначала идет Bitmap Index Scan, для поиска адрес строк, а уже потом идет Bitmap Heap Scan для получения нужных строк с результатом поиска.  
Для текстового поиска, согласно документации, предпочтительными являются GIN-индексы. GIN-индексы представляют собой инвертированные индексы, в которых могут содержаться значения с несколькими ключами.  
Будучи инвертированными индексами, они содержат записи для всех отдельных слов (лексем) с компактным списком мест их вхождений. 

#### Работа с индексом на часть таблицы:
Создаем индекс:
```
test_indexes=# CREATE INDEX idx_products_is_available_true
test_indexes-#     ON products(is_available)
test_indexes-#     WHERE is_available = true;
CREATE INDEX
```
Смотрим план, где идет поиск по индексируемому значению:  
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE is_available = true;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using idx_products_is_available_true on products  (cost=0.29..10341.56 rows=96000 width=14)
(1 row)
```
Видим, что идет  Index Scan.  
Посмотрим другой запрос:  
```
SELECT * FROM products
    WHERE is_available = false;
                                   QUERY PLAN
---------------------------------------------------------------------------------
 Seq Scan on products  (cost=0.00..163695.00 rows=9904000 width=14)
   Filter: (NOT is_available)
 JIT:
   Functions: 2
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(5 rows)
```
Видим,что идет последовательное сканирование таблицы: Seq Scan.
Частичные индексы индексируют лишь подмножество строк таблицы. Это позволяет экономить размер индексов и быстрее выполнять сканирование.   
Эффективно применять когда выборка по индексироуемому значению происходит очень часто, например в таблице используется поле sysactive со значениями Y/D/U. И чаще всего выбираеются данные со значением поля: Y.

#### Работа с индексом на несколько полей:  
Смотрим на план запросов до создания индексов:
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id <= 10000
test_indexes-#     AND brand = 'a';
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=215.53..29903.56 rows=121 width=14)
   Recheck Cond: (product_id <= 10000)
   Filter: (brand = 'a'::bpchar)
   ->  Bitmap Index Scan on idx_products_product_id  (cost=0.00..215.50 rows=11609 width=0)
         Index Cond: (product_id <= 10000)
(5 rows)

test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id = 1780
test_indexes-#     AND brand <= 'a';
                                       QUERY PLAN
-----------------------------------------------------------------------------------------
 Index Scan using idx_products_product_id on products  (cost=0.43..8.46 rows=1 width=14)
   Index Cond: (product_id = 1780)
   Filter: (brand <= 'a'::bpchar)
(3 rows)
```
Создаем индексы:  
```
test_indexes=# CREATE INDEX
    idx_products_product_id_brand
    ON products(product_id, brand);
CREATE INDEX
test_indexes=# CREATE INDEX
    idx_products_brand_product_id
    ON products(brand, product_id);
CREATE INDEX
```

Смотрим планы запросов:
```
test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id <= 10000
test_indexes-#     AND brand = 'a';
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=5.68..475.67 rows=121 width=14)
   Recheck Cond: ((brand = 'a'::bpchar) AND (product_id <= 10000))
   ->  Bitmap Index Scan on idx_products_brand_product_id  (cost=0.00..5.64 rows=121 width=0)
         Index Cond: ((brand = 'a'::bpchar) AND (product_id <= 10000))
(4 rows)

test_indexes=# EXPLAIN
test_indexes-# SELECT * FROM products
test_indexes-#     WHERE product_id = 1780
test_indexes-#     AND brand <= 'a';
                                          QUERY PLAN
-----------------------------------------------------------------------------------------------
 Index Scan using idx_products_product_id_brand on products  (cost=0.43..8.46 rows=1 width=14)
   Index Cond: ((product_id = 1780) AND (brand <= 'a'::bpchar))
(2 rows)
```

Для первого случая теперь вместо ранее созданного индекса idx_products_product_id используется составной индекс idx_products_brand_product_id, причем сначала  
идет Bitmap Index Scan, для поиска адрес строк, а уже потом идет Bitmap Heap Scan для получения нужных строк с результатом поиска.
Для второго случая идет сканирование по индексу idx_products_product_id_brand.

Составные индексы применяются в случаях, когда часто идут выборки по условию из нескольких полей.
