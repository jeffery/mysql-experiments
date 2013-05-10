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
		DECLARE baseQuery VARCHAR(100) DEFAULT CONCAT( 'INSERT INTO ', tableName, ' VALUES ' );
		DECLARE firstLoop BOOLEAN DEFAULT TRUE;
		DECLARE recordCount INT DEFAULT 0;
		DECLARE rowsPerQuery INT DEFAULT 1000;
		SET @fullQuery = baseQuery;

		CALL createTable( tableName, engineType );

		WHILE recordCount < maximumRecords
		DO
		IF ( counter = rowsPerQuery )
		THEN
			SET firstLoop = TRUE;
			SET counter = 0;
			PREPARE preparedStatement FROM @fullQuery;
			EXECUTE preparedStatement;
			DEALLOCATE PREPARE preparedStatement;
			SET @fullQuery = baseQuery;
			SET step = step + 1;
			SELECT
				step
				, recordCount
				, now( );
		END IF;

		IF ( firstLoop )
		THEN
			SET firstLoop = FALSE;
		ELSE
			SET @fullQuery = concat( @fullQuery, ',' );
		END IF;

		SET @queryFragment = CONCAT(
				'(',
				recordCount,
				',', "'", 'Testing Data', "'",
				',', "'", startDate, "'", ' + INTERVAL ', FLOOR( RAND( ) * dataDays ), ' DAY',
				')'
		);

		SET @fullQuery = CONCAT(
				@fullQuery,
				@queryFragment
		);
		SET recordCount = recordCount + 1;
		SET counter = counter + 1;
		END WHILE;

		IF ( counter )
		THEN
			PREPARE preparedStatement FROM @fullQuery;
			EXECUTE preparedStatement;
			DEALLOCATE PREPARE preparedStatement;
		END IF;

	END
//
DELIMITER ;