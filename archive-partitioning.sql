DROP TABLE if exists no_partition_table;

CREATE TABLE no_partition_table
(
  c1 int(11) default NULL,
  c2 varchar(30) default NULL,
  c3 date default NULL
) engine=MYISAM;

DROP TABLE if exists partition_myisam_table;

CREATE TABLE partition_myisam_table
(
  c1 int default NULL,
  c2 varchar(30) default NULL,
  c3 date default NULL
) engine=MYISAM
PARTITION BY RANGE ( year( c3 ) ) (
  PARTITION p0 VALUES LESS THAN (1995),
  PARTITION p1 VALUES LESS THAN (1996),
  PARTITION p2 VALUES LESS THAN (1997),
  PARTITION p3 VALUES LESS THAN (1998),
  PARTITION p4 VALUES LESS THAN (1999),
  PARTITION p5 VALUES LESS THAN (2000),
  PARTITION p6 VALUES LESS THAN (2001),
  PARTITION p7 VALUES LESS THAN (2002),
  PARTITION p8 VALUES LESS THAN (2003),
  PARTITION p9 VALUES LESS THAN (2004),
  PARTITION p10 VALUES LESS THAN (2010),
  PARTITION p11 VALUES LESS THAN MAXVALUE
);

DROP TABLE if exists partition_archive_table;
CREATE TABLE partition_archive_table (
  c1 int(11) not null ,
  c2 varchar(30) default NULL,
  c3 date default NULL
-- unique key (c1)
) ENGINE=ARCHIVE DEFAULT CHARSET=latin1
PARTITION BY RANGE ( year( c3 ) )
(
  PARTITION p0 VALUES LESS THAN (1995),
  PARTITION p1 VALUES LESS THAN (1996),
  PARTITION p2 VALUES LESS THAN (1997),
  PARTITION p3 VALUES LESS THAN (1998),
  PARTITION p4 VALUES LESS THAN (1999),
  PARTITION p5 VALUES LESS THAN (2000),
  PARTITION p6 VALUES LESS THAN (2001),
  PARTITION p7 VALUES LESS THAN (2002),
  PARTITION p8 VALUES LESS THAN (2003),
  PARTITION p9 VALUES LESS THAN (2004),
  PARTITION p10 VALUES LESS THAN (2010),
  PARTITION p11 VALUES LESS THAN MAXVALUE
  ENGINE = ARCHIVE
);


delimiter //

drop procedure if exists load_partition_myisam_table //

CREATE PROCEDURE load_partition_myisam_table( max_recs int, rows_per_query int )
begin
  declare counter int default 0;
  declare step int default 0;
  declare base_query varchar(100) default 'insert into partition_myisam_table values ';
  declare first_loop boolean default true;
  declare v int default 0;
  set @query = base_query;

  while v < max_recs
  do
    if ( counter = rows_per_query ) then
       set first_loop = true;
       set counter = 0;
       prepare q from @query;
       execute q;
       deallocate prepare q;
       set @query = base_query;
       set step = step + 1;
       select step, v, now();
    end if;

    if (first_loop) then
       set first_loop = false;
    else
       set @query = concat(@query, ',');
    end if;

    set @query = concat(
      @query,
      '(', v, ',',
      '"testing partitions"',',"',
      adddate('1995-01-01',( rand( v ) * 36520 ) mod 3652 ), '")'
    );
    set v = v + 1;
    set counter = counter + 1;
  end while;

  if (counter) then
     prepare q from @query;
     execute q;
     deallocate prepare q;
  end if;

end
//
delimiter ;

call load_partition_myisam_table( 10000000, 1000 );
insert into no_partition_table select * from partition_myisam_table;
insert into partition_archive_table select * from partition_myisam_table;

select  count(*) from no_partition_table where c3 > date '1995-01-01' and c3 < date '1995-12-31';
select  count(*) from partition_myisam_table where c3 > date '1995-01-01' and c3 < date '1995-12-31';
select  count(*) from partition_archive_table where c3 > date '1995-01-01' and c3 < date '1995-12-31';