CALL createTableData( 'raw_table_data', 'myisam', 5000000, 1000 );

CALL createTablePartitionedByDateRange( 'partitioned_table', 'archive', 'createdDate', 10, 'y' );

CALL commitProcedureLog( );

INSERT INTO partitioned_table
	SELECT
		*
	FROM raw_table_data;

SELECT
	count( * )
FROM raw_table_data
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';

SELECT
	count( * )
FROM partitioned_table
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';

