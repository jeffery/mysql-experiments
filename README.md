mysql-experiments
=================

Various MySQL/MariaDB database experiments, mostly stored procedures

Prune Table Tests - test-prune-tables.sql
=========================================

This test is performed to see how fast a large data-set can be pruned given the
number of days, data is to be retained.

The stored procedure pruneTableData ( prune-table-data.sql ) is called to prune
the table data on the basis of the data present in the createdDate column of
the table. The procedure accepts three arguments:

	* The retention days
	* Table name
	* Table date column name

The logic of pruning is based on copying the 'good' data to a new table and then
re-naming the tables. This consumes time and disk IO.


Partitioning Table Tests - test-partitioned-tables.sql
======================================================

This test is performed to see how fast queries are returned from a partitioned
table, compared to a non-partitioned table.

The stored procedure partitionTableByDateRange is used to create partitions by
Date range on a table which has a date column. The procedure accepts four
arguments:

	* Table name
	* Table engine type
	* Partitioning range date column name
	* Partition range type. One of y, m or d


Create Table
============

The stored procedure createTable ( create-table.sql ) is used to create a table
of type engine. The table is dropped before re-creation. The table schema
contains the following columns:

	dataSerial int default NULL,
	description varchar(30) default NULL,
	createdDate date default NULL

The procedure accepts two arguments:

	* Table name
	* Table engine type


Create Table Data
=================

The stored procedure createTableData ( create-table-data.sql ) is used to
create test data for running various SQL performance tests. The procedure
accepts five arguments:

	 * Table name
	 * Table engine type
	 * Number of records to create
	 * How many days of data to create
	 * The start date of the data

Before creating the data, it creates the table schema using the procedure
createTable


Procedure Log
=============

The stored procedure procedureLog ( procedureLog.sql ) is used to log the
actions performed by the above stored procedures

