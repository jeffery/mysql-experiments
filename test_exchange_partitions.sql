# ############################
# test_exchange_partitions.sql
# ############################
use mysql_experiments;
set default_storage_engine=innodb;
drop procedure if exists compare_tables;
delimiter //
create procedure compare_tables (wanted int)
reads sql data
begin
    set @part_table     := (select count(*) from compare_table1);
    set @non_part_table := (select count(*) from compare_table2);
    select @part_table, @non_part_table,
        if(@non_part_table = wanted, "OK", "error") as expected;
end //
delimiter ;

drop table if exists compare_table1, compare_table2;
create table
  compare_table1 (i int) # not null primary key)
partition by range (i)
(
  partition p01 values less than  (100001),
  partition p02 values less than  (200001),
  partition p03 values less than  (300001),
  partition p04 values less than  (400001),
  partition p05 values less than  (500001),
  partition p06 values less than  (600001),
  partition p07 values less than  (700001),
  partition p08 values less than  (800001),
  partition p09 values less than  (900001),
  partition p10 values less than (1000001),
  partition p11 values less than (maxvalue)
);

create table compare_table2 (i int ) ; # not null primary key);

select table_name, engine
from information_schema.tables
where table_schema='mysql_experiments' and table_type='base table';


select 'generating 1 million records. ...' as info;
# generates 1 million records
# see this article for details
# http://datacharmer.blogspot.com/2007/12/data-from-nothing-solution-to-pop-quiz.html
create or replace view v3 as select null union all select null union all select null;
create or replace view v10 as select null from v3 a, v3 b union all select null;
create or replace view v1000 as select null from v10 a, v10 b, v10 c;
set @n = 0;
insert into compare_table1 select @n:=@n+1 from v1000 a,v1000 b;

select
  partition_name,
  table_rows
from
  information_schema . partitions
where
  table_name='compare_table1'
  and
  table_schema='mysql_experiments';

call compare_tables(0);

alter table compare_table1 exchange partition p04 with table compare_table2;
call compare_tables(100000);

select
  partition_name,
  table_rows
from
  information_schema . partitions
where
  table_name='compare_table1'
  and
  table_schema='mysql_experiments';

alter table compare_table1 exchange partition p04 with table compare_table2;
call compare_tables(0);

alter table compare_table1 exchange partition p04 with table compare_table2;
call compare_tables(100000);