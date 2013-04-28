DELIMITER //

DROP PROCEDURE IF EXISTS createTable //

CREATE PROCEDURE createTable( IN tableName CHAR(64), IN engineType CHAR(10) )
	BEGIN
		SET @dropTable = CONCAT( 'DROP TABLE IF EXISTS ', tableName );
		PREPARE dropStatement FROM @dropTable;
		EXECUTE dropStatement;
		CALL procedureLog( CONCAT( 'Dropping Table ', tableName, ' if it Exists ' ) );

		SET @createTable = CONCAT( 'CREATE TABLE ', tableName, ' (
        dataSerial int default NULL,
        description varchar(30) default NULL,
        createdDate date default NULL
      ) engine=', engineType
		);

		PREPARE createStatement FROM @createTable;
		EXECUTE createStatement;
		CALL procedureLog( CONCAT( 'Creating Table ', @createTable ) );
	END
//


DROP PROCEDURE IF EXISTS createTablePartitionedByDateRange //

CREATE PROCEDURE createTablePartitionedByDateRange( IN tableName            CHAR(64),
																										IN engineType           CHAR(10),
																										IN partitionRangeColumn CHAR(64),
																										IN partitionCount       INT(3),
																										IN partitionRangeType   CHAR(1) )
	BEGIN
		DECLARE partitionCounter INT DEFAULT 0;
		DECLARE partitionRange CHAR(20) DEFAULT '';
		DECLARE currentRange INT;
		DECLARE createPartitionTable TEXT DEFAULT '';

		CALL procedureLog( 'Creating partitioned Table by Range' );

		CALL createTable( tableName, engineType );

		SET createPartitionTable = CONCAT(
				createPartitionTable,
				'ALTER TABLE ',
				tableName,
				' PARTITION BY RANGE ( TO_DAYS( ',
				partitionRangeColumn,
				' ) ) ( '
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
				'PARTITION p', partitionCounter, ' VALUES LESS THAN (TO_DAYS(', "'", partitionRange, "'", ')), '
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