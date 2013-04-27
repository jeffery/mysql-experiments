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
		CALL procedureLog( CONCAT( 'Creating Table ', tableName ) );
	END
//


DROP PROCEDURE IF EXISTS createTablePartitionedByRange //

CREATE PROCEDURE createTablePartitionedByRange( IN tableName            CHAR(64),
																								IN engineType           CHAR(10),
																								IN partitionRangeColumn CHAR(64),
																								IN partitionRange       INT(3),
																								IN partitionRangeType   CHAR(1) )
	BEGIN
		DECLARE partitionCounter INT DEFAULT 0;
		DECLARE currentYear, partitionYear INT;
		DECLARE createPartitionTable TEXT DEFAULT '';

		SET currentYear = (
			SELECT
				YEAR( CURRENT_DATE( ) )
		);
		CALL procedureLog( 'Creating partitioned Table by Range' );

		CALL createTable( tableName, engineType );

		SET createPartitionTable = CONCAT(
				createPartitionTable,
				'ALTER TABLE ', tableName, ' PARTITION BY RANGE ( YEAR( ', partitionRangeColumn, ' ) ) ( '
		);

		WHILE partitionCounter < partitionRange
		DO
		SET partitionYear = currentYear - partitionRange + partitionCounter;
		CALL procedureLog( CONCAT( 'Partitioning for Year: ', partitionYear ) );

		SET createPartitionTable = CONCAT(
				createPartitionTable,
				'PARTITION p', partitionCounter, ' VALUES LESS THAN (', partitionYear, '), '
		);
		SET partitionCounter = partitionCounter + 1;
		END WHILE;

		SET createPartitionTable = CONCAT( createPartitionTable, 'PARTITION pMAX VALUES LESS THAN MAXVALUE ' );
		SET createPartitionTable = CONCAT( createPartitionTable, 'ENGINE = ', engineType, ')' );

		SET @sqlStatement = createPartitionTable;
		PREPARE query FROM @sqlStatement;
		EXECUTE query;
		DEALLOCATE PREPARE query;
		CALL procedureLog( CONCAT( 'Altering Table for partitions: ', createPartitionTable ) );

	END
//

DELIMITER ;

CALL createTablePartitionedByRange( 'partitioned_table', 'archive', 'createdDate', 20, 'y' );
CALL commitProcedureLog( );