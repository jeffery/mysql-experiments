DELIMITER //

DROP PROCEDURE IF EXISTS setupProcedureLog //
CREATE PROCEDURE setupProcedureLog( )
	BEGIN
		DECLARE procedureLogExists INT DEFAULT 0;

		SELECT
			count( * )
		INTO procedureLogExists
		FROM information_schema.tables
		WHERE table_schema = database( ) AND table_name = 'procedureLog';

		IF procedureLogExists = 0
		THEN
			CREATE TABLE procedureLog (
				id           INT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
				logTime      DATETIME,
				connectionId INT             NOT NULL DEFAULT 0,
				logMessage   VARCHAR(512),
				PRIMARY KEY (id)
			);
		ELSE
			TRUNCATE TABLE procedureLog;
		END IF;

		CREATE TEMPORARY TABLE IF NOT EXISTS procedureLogMemory (
			id           INT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
			logTime      TIMESTAMP,
			connectionId INT             NOT NULL DEFAULT 0,
			logMessage   VARCHAR(512),
			PRIMARY KEY (id)
		)
			ENGINE = MEMORY;

	END
//


DROP PROCEDURE IF EXISTS procedureLog //
CREATE PROCEDURE procedureLog( IN logMsg VARCHAR(512) )
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLSTATE '42S02' -- Table not found
		BEGIN
			CALL setupProcedureLog( );
			INSERT INTO procedureLogMemory (connectionId, logMessage) VALUES (connection_id( ), 'Start Log');
			INSERT INTO procedureLogMemory (connectionId, logMessage) VALUES (connection_id( ), logMsg);
		END;

		INSERT INTO procedureLogMemory (connectionId, logMessage) VALUES (connection_id( ), logMsg);
	END
//


DROP PROCEDURE IF EXISTS refreshProcedureLog //
CREATE PROCEDURE refreshProcedureLog( )
	BEGIN
		CALL procedureLog( 'Finish Log' );
		INSERT INTO procedureLog
			SELECT
				*
			FROM procedureLogMemory;
		DROP TABLE procedureLogMemory;
	END
//

DELIMITER ;