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
