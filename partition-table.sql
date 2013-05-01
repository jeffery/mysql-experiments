DELIMITER //

DROP PROCEDURE IF EXISTS partitionTableByDateRange //

CREATE PROCEDURE partitionTableByDateRange( IN tableName            CHAR(64),
																						IN engineType           CHAR(10),
																						IN partitionRangeColumn CHAR(64),
																						IN partitionRangeType   CHAR(1) )
	BEGIN
		DECLARE partitionCounter INT DEFAULT 0;
		DECLARE partitionCount INT DEFAULT 0;
		DECLARE partitionRange CHAR(20) DEFAULT '';
		DECLARE currentRange INT;
		DECLARE createPartitionTable TEXT DEFAULT '';
		DECLARE alterTableExists INT DEFAULT 0;
		DECLARE dateDistance INT DEFAULT 0;
		DECLARE tableNotCreated CONDITION FOR SQLSTATE '42S02';
		DECLARE errorMessage TEXT DEFAULT '';
		DECLARE currentDatabase CHAR(64) DEFAULT DATABASE( );


		DECLARE CONTINUE HANDLER FOR tableNotCreated
		BEGIN
			SET errorMessage = CONCAT( 'Table ', tableName, ' does not exist, cannot alter non existent table' );
			CALL procedureLog( errorMessage );
			CALL commitProcedureLog;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = errorMessage;
		END;

		CALL procedureLog( CONCAT( 'Database is ', currentDatabase ) );

		SELECT
			count( * )
		INTO alterTableExists
		FROM information_schema.tables
		WHERE table_schema = currentDatabase AND table_name = tableName;

		IF alterTableExists = 0
		THEN
			SIGNAL tableNotCreated
			SET MESSAGE_TEXT = 'Table does not exist, cannot alter non existent table';
		END IF;

		CALL procedureLog(
				CONCAT(
						'Modifying table ',
						tableName,
						', Partitioned by Date Range: ',
						alterTableExists
				)
		);

		SET @distance := 0;
		SET @dateSql := CONCAT(
				'SELECT DATEDIFF( MAX( createdDate ), MIN( createdDate ) ) INTO @distance FROM ',
				tableName
		);
		PREPARE statement FROM @dateSql;
		EXECUTE statement;
		DEALLOCATE PREPARE statement;
		SET dateDistance = @distance;

		CALL procedureLog( CONCAT( 'Date Distance is ', dateDistance, ' days' ) );

		IF ( dateDistance > 0 )
		THEN
			BEGIN
				IF ( ( dateDistance > 31146 AND dateDistance <= 373760 ) OR
						 ( dateDistance <= 373760 AND partitionRangeType = 'y' ) )
				-- 373,760 days = 1024 years
				THEN
					SET partitionRangeType = 'y';
					SET partitionCount = CEIL( dateDistance * 1 / 365 );
				ELSEIF ( ( dateDistance > 1024 AND dateDistance <= 31146 ) OR
								 ( dateDistance <= 31146 AND partitionRangeType = 'm' ) )
					-- 31146 days = 1024 months
					THEN
						SET partitionRangeType = 'm';
						SET partitionCount = CEIL( dateDistance * 12 / 365 );
				ELSEIF ( dateDistance <= 1024 AND partitionRangeType = 'd' )
					-- 1024 partitions is the limit
					THEN
						SET partitionCount = dateDistance;
						SET partitionRangeType = 'd';
				ELSE
					CALL commitProcedureLog;
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'Could not calculate valid Partitioning scheme';
				END IF;
			END;
		ELSE
			CALL commitProcedureLog;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'The table being partitioned should contain some data to determine the partitioning scheme';
		END IF;

		CALL procedureLog( CONCAT( 'Partition count is ', partitionCount, ' for partition type ', partitionRangeType ) );

		SET createPartitionTable = CONCAT(
				createPartitionTable,
				'ALTER TABLE ',
				tableName,
				' PARTITION BY RANGE COLUMNS ( ',
				partitionRangeColumn,
				' ) ( '
		);

		REPEAT
		SET currentRange = partitionCounter - partitionCount;
		SET partitionRange = (
			SELECT
				CASE
				WHEN partitionRangeType = 'd' THEN
					DATE_FORMAT( DATE_ADD( CURDATE( ), INTERVAL currentRange DAY ), '%Y-%m-%d' )
				WHEN partitionRangeType = 'm' THEN
					DATE_FORMAT( DATE_ADD( CURDATE( ), INTERVAL currentRange MONTH ), '%Y-%m-01' )
				WHEN partitionRangeType = 'y' THEN
					DATE_FORMAT( DATE_ADD( CURDATE( ), INTERVAL currentRange YEAR ), '%Y-01-01' )
				END
		);

		CALL procedureLog( CONCAT( 'Partitioning for Range: ', partitionRange ) );

		SET createPartitionTable = CONCAT(
				createPartitionTable,
				'PARTITION p', partitionCounter, ' VALUES LESS THAN (', "'", partitionRange, "'", '), '
		);
		SET partitionCounter = partitionCounter + 1;
		UNTIL partitionCounter > partitionCount
		END REPEAT;

		SET createPartitionTable = CONCAT( createPartitionTable, 'PARTITION pMAX VALUES LESS THAN MAXVALUE ' );
		SET createPartitionTable = CONCAT( createPartitionTable, 'ENGINE = ', engineType, ')' );

		CALL procedureLog( CONCAT( 'Altering Table for partitions: ', createPartitionTable ) );
		SET @sqlStatement = createPartitionTable;
		PREPARE query FROM @sqlStatement;
		EXECUTE query;
		DEALLOCATE PREPARE query;
	END
//
DELIMITER ;