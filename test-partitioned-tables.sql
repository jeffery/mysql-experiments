-- CALL createTableData( 'raw_table_data', 'myisam', 5000000, 1000 );

CALL createTable( 'partitioned_table', 'archive' );

INSERT INTO partitioned_table
	SELECT
		*
	FROM raw_table_data;

CALL partitionTableByDateRange( 'partitioned_table', 'archive', 'createdDate', 100, 'm' );
SHOW ERRORS LIMIT 1;

CALL commitProcedureLog( );

SELECT
	count( * )
FROM raw_table_data
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';

SELECT
	count( * )
FROM partitioned_table
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';