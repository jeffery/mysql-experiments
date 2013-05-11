CALL createTableData( 'raw_table_data', 'myisam', 5000000, 3652, '2003-01-01' );

/**
CALL createTableData( 'raw_table_data', 'myisam', 5000000, 3652, '2003-01-01' );

Above call creates about 1300+ records per day for 10 years starting from 2003-01-01

SELECT DATE_FORMAT(  `createdDate` ,  '%Y-%m-%d' ) AS NewDate, COUNT( createdDate )
FROM  `raw_table_data`
WHERE 1
GROUP BY NewDate
 */
CALL createTable( 'partitioned_table', 'archive' );

INSERT INTO partitioned_table
	SELECT
		*
	FROM raw_table_data;

CALL partitionTableByDateRange( 'partitioned_table', 'archive', 'createdDate', 'y' );
SHOW ERRORS LIMIT 1;


SELECT
	count( * )
FROM raw_table_data
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';

SELECT
	count( * )
FROM partitioned_table
WHERE createdDate > DATE '2003-01-01' AND createdDate < DATE '2003-12-31';