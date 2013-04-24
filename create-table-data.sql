DELIMITER //

DROP PROCEDURE IF EXISTS createTableData //

CREATE PROCEDURE createTableData( IN tableName    CHAR(64), IN engineType CHAR(10), IN maximumRecords INT,
																	IN rowsPerQuery INT )
	BEGIN
		DECLARE counter INT DEFAULT 0;
		DECLARE step INT DEFAULT 0;
		DECLARE base_query VARCHAR(100) DEFAULT CONCAT( 'INSERT INTO ', tableName, ' VALUES ' );
		DECLARE first_loop BOOLEAN DEFAULT TRUE;
		DECLARE v INT DEFAULT 0;
		SET @query = base_query;

		SET @dropTable = CONCAT( 'DROP TABLE IF EXISTS ', tableName );
		PREPARE dropStatement FROM @dropTable;
		EXECUTE dropStatement;

		SET @createTable = CONCAT( 'CREATE TABLE ', tableName, ' (
        dataSerial int default NULL,
        description varchar(30) default NULL,
        createdDate date default NULL
      ) engine=', engineType
		);
		PREPARE createStatement FROM @createTable;
		EXECUTE createStatement;
		CALL procedureLog(CONCAT('Creating Table ',tableName));

		WHILE v < maximumRecords
		DO
		IF (counter = rowsPerQuery)
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
				, v
				, now( );
		END IF;

		IF (first_loop)
		THEN
			SET first_loop = FALSE;
		ELSE
			SET @query = concat( @query, ',' );
		END IF;

		SET @query = CONCAT(
				@query,
				'(', v, ',',
				'"testing Data"', ',"',
				adddate( '2003-01-01', (rand( v ) * 36520) MOD 3652 ), '")'
		);
		SET v = v + 1;
		SET counter = counter + 1;
		END WHILE;

		IF (counter)
		THEN
			PREPARE q FROM @query;
			EXECUTE q;
			DEALLOCATE PREPARE q;
		END IF;

	END
//
DELIMITER ;