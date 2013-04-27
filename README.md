mysql-experiments
=================

	Various MySQL/MariaDB database experiments

Prune Table Tests - Generic
==

	This test is performed to see how fast a large data-set can be pruned given
	the number of days, data is to be retain.

	The stored procedure createTableData ( create-table-data.sql ) is called to
	create a myisam table with 5,000,000 rows of data.

	The stored procedure pruneTableData ( prune-table-data.sql ) is called to
	prune the table data on the basis of the data present in the createdDate
	column of the table.

Procedure Log
==

	The stored procedure procedureLog ( procedureLog.sql ) is used to log the
	actions performed by the above stored procedures

