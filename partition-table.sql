DELIMITER //

DROP PROCEDURE IF EXISTS partitionTableByDateRange //

CREATE PROCEDURE partitionTableByDateRange( IN tableName            CHAR(64),
																						IN engineType           CHAR(10),
																						IN partitionRangeColumn CHAR(64),
																						IN partitionCount       INT(3),
																						IN partitionRangeType   CHAR(1) )
	BEGIN
		DECLARE partitionCounter INT DEFAULT 0;
		DECLARE partitionRange CHAR(20) DEFAULT '';
		DECLARE currentRange INT;
		DECLARE createPartitionTable TEXT DEFAULT '';
		DECLARE alterTableExists INT DEFAULT 0;
		DECLARE dateDistance INT DEFAULT 0;
		DECLARE tableNotCreated CONDITION FOR SQLSTATE '42S02';
		DECLARE errorMessage TEXT DEFAULT '';

		DECLARE CONTINUE HANDLER FOR tableNotCreated
		BEGIN
			SET errorMessage = CONCAT( 'Table ', tableName, ' does not exist, cannot alter non existent table' );
			CALL procedureLog( errorMessage );
			CALL commitProcedureLog;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = errorMessage;
		END;

		SELECT
			count( * )
		INTO alterTableExists
		FROM information_schema.tables
		WHERE table_schema = DATABASE() AND table_name = tableName;

		IF alterTableExists = 0
		THEN
			SIGNAL tableNotCreated
			SET MESSAGE_TEXT = 'Table does not exist, cannot alter non existent table';
		END IF;

		CALL procedureLog( CONCAT( 'Modifying table ', tableName, ', Partitioned by Date Range' ) );

		SELECT
			DATEDIFF( MAX( createdDate ), MIN( createdDate ) )
		INTO dateDistance
		FROM tableName;


		CALL procedureLog( CONCAT( 'Date Distance is ', dateDistance ) );

		IF ( dateDistance != NULL AND dateDistance > 0 )
		THEN
			BEGIN
				IF ( dateDistance > 31146 AND dateDistance <= 373760 OR dateDistance <= 373760 AND partitionRangeType = 'y' )
				-- 373,760 days = 1024 years
				THEN
					SET partitionRangeType = 'y';
					SET partitionCount = dateDistance * CEIL( 1 / 365 );
				ELSEIF ( dateDistance > 1024 AND dateDistance <= 31146 OR dateDistance <= 31146 AND partitionRangeType = 'm' )
					-- 31146 days = 1024 months
					THEN
						SET partitionRangeType = 'm';
						SET partitionCount = dateDistance * CEIL( 12 / 365 );
				ELSEIF ( dateDistance <= 1024 OR partitionRangeType = 'd' )
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