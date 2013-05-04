DELIMITER //

DROP PROCEDURE IF EXISTS createTableData //

CREATE PROCEDURE createTableData( IN tableName      CHAR(64),
																	IN engineType     CHAR(10),
																	IN maximumRecords INT,
																	IN dataDays       INT,
																	IN startDate      CHAR(10) )
	BEGIN
		DECLARE counter INT DEFAULT 0;
		DECLARE step INT DEFAULT 0;
		DECLARE base_query VARCHAR(100) DEFAULT CONCAT( 'INSERT INTO ', tableName, ' VALUES ' );
		DECLARE first_loop BOOLEAN DEFAULT TRUE;
		DECLARE recordCount INT DEFAULT 0;
		DECLARE rowsPerQuery INT DEFAULT 1000;
		SET @query = base_query;

		CALL createTable( tableName, engineType );

		WHILE recordCount < maximumRecords
		DO
		IF ( counter = rowsPerQuery )
		THEN
			SET first_loop = TRUE;
			SET counter = 0;
			PREPARE q FROM @query;
			EXECUTE q;
			DEALLOCATE PREPARE q;
			SET @query = base_query;
			SET step = step + 1;
			SELECT
				step
				, recordCount
				, now( );
		END IF;

		IF ( first_loop )
		THEN
			SET first_loop = FALSE;
		ELSE
			SET @query = concat( @query, ',' );
		END IF;

		SET @queryFragment = CONCAT(
				'(',
				recordCount,
				',', "'", 'Testing Data', "'",
				',', "'", startDate, "'", ' + INTERVAL ', FLOOR( RAND( ) * dataDays ), ' DAY',
				')'
		);

		SET @query = CONCAT(
				@query,
				@queryFragment
		);
		SET recordCount = recordCount + 1;
		SET counter = counter + 1;
		END WHILE;

		IF ( counter )
		THEN
			PREPARE q FROM @query;
			EXECUTE q;
			DEALLOCATE PREPARE q;
		END IF;

	END
//
DELIMITER ;