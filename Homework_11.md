### DML-триггеры

#### Создаем таблицы и заполняем данными:

```
postgres=# CREATE TABLE goods (   goods_id    integer PRIMARY KEY,
postgres(#     good_name   varchar(63) NOT NULL,
postgres(#     good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0));
ostgres=# INSERT INTO goods (goods_id, good_name, good_price) VALUES ( (1, 'Спички хозайственные', .50),(2, 'Автомобиль Ferrari FXX K', 185000000.01);
postgres=# CREATE TABLE pract_functions.sales
postgres-# (    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
postgres(#     good_id     integer REFERENCES pract_functions.goods (goods_id),
postgres(#     sales_time  timestamp with time zone DEFAULT now(),
postgres(#     sales_qty   integer CHECK (sales_qty > 0));
CREATE TABLE
INSERT INTO pract_functions.sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
postgres=# CREATE TABLE pract_functions.good_sum_mart
postgres-# (good_name   varchar(63) NOT NULL,
postgres(# sum_sale numeric(16, 2) NOT NULL);
CREATE TABLE
```
#### Пишем триггер:   
Функция:  
```
CREATE OR REPLACE FUNCTION pract_functions.tf_sales()
RETURNS trigger
AS
$$
DECLARE
    row_dbg record;
BEGIN
    CASE TG_OP
        WHEN 'INSERT' THEN
			with tbl as (
	            SELECT G.good_name, COALESCE(sum(G.good_price * S.sales_qty),0) sum_sale
                FROM pract_functions.goods G
                LEFT JOIN pract_functions.sales S ON S.good_id = G.goods_id
				where G.goods_id=new.good_id
                GROUP BY G.good_name
                    )
              merge INTO pract_functions.good_sum_mart ca
              using tbl
                   on ca.good_name=tbl.good_name
              WHEN MATCHED  THEN 
              UPDATE SET sum_sale = tbl.sum_sale
              WHEN NOT MATCHED THEN
              INSERT (good_name, sum_sale)
              VALUES (tbl.good_name, tbl.sum_sale);
			  RETURN NEW;

        WHEN 'DELETE' THEN
			with tbl as (
	            SELECT G.good_name, COALESCE(sum(G.good_price * S.sales_qty),0) sum_sale
                FROM pract_functions.goods G
                LEFT JOIN pract_functions.sales S ON S.good_id = G.goods_id
				where G.goods_id=old.good_id
                GROUP BY G.good_name
                    )
              merge INTO pract_functions.good_sum_mart ca
              using tbl
                   on ca.good_name=tbl.good_name
              WHEN MATCHED  THEN 
              UPDATE SET sum_sale = tbl.sum_sale
              WHEN NOT MATCHED THEN
              INSERT (good_name, sum_sale)
              VALUES (tbl.good_name, tbl.sum_sale)
			 WHEN MATCHED and tbl.sum_sale=0 then delete;
			 RETURN OLD;

        WHEN 'UPDATE' THEN
					with tbl as (
	            SELECT G.good_name, COALESCE(sum(G.good_price * S.sales_qty),0) sum_sale
                FROM pract_functions.goods G
                LEFT JOIN pract_functions.sales S ON S.good_id = G.goods_id
				where G.good_name = (select distinct good_name from pract_functions.sales where sales_qty=new.sales_qty)
                GROUP BY G.good_name
                    )
              merge INTO pract_functions.good_sum_mart ca
              using tbl
                   on ca.good_name=tbl.good_name
              WHEN MATCHED  THEN 
              UPDATE SET sum_sale = tbl.sum_sale
              WHEN NOT MATCHED THEN
              INSERT (good_name, sum_sale)
              VALUES (tbl.good_name, tbl.sum_sale);
			   RETURN NEW;
    END CASE;
END
$$ LANGUAGE plpgsql;
```

Триггер:   
```
CREATE TRIGGER trg_edit_sales
AFTER INSERT OR UPDATE OR DELETE
ON pract_functions.sales
FOR EACH ROW
EXECUTE FUNCTION pract_functions.tf_sales();
```


#### Проверяем работу: 

Добавим в таблицу goods новый товар и продажу по нему:
```
postgres=# insert into pract_functions.sales(good_id, sales_qty) values (3,1);
INSERT 0 1
```
Смотрим витрину:
```
postgres=# select * from pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Товар                    |        45.00
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 185000000.01
(3 rows)
```
Видим строку с нашим товаром.

Делаем Update(увеличиваем количество с 1 до 3):  
```
postgres=# update pract_functions.sales set sales_qty=3 where good_id=3;
UPDATE 1
postgres=# select * from pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Товар                    |       135.00
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 185000000.01
(3 rows)
```
Видим, что вирина обновилась.

Делаем delete:
```
postgres=# delete from pract_functions.sales where good_id=3;
DELETE 1
postgres=# select * from pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 185000000.01
(2 rows)

postgres=#
```
Видим, что из витрины пропала запись с новым товаром.

Даная витрина кроме выйгрыша производительности дает всегда актуальные данные, если еще отслеживать в триггере изменение цены товара, то данные будут всегда акуальны.
