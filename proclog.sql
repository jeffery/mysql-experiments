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
			CREATE TABLE IF NOT EXISTS procedureLog (
				id           INT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
				logTime      DATETIME,
				connectionId INT             NOT NULL DEFAULT 0,
				logMessage   VARCHAR(512),
				PRIMARY KEY (id)
			);
		END IF;

		CREATE TEMPORARY TABLE IF NOT EXISTS tmp_procedureLog (
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
			INSERT INTO tmp_procedureLog (connectionId, logMessage) VALUES (connection_id( ), 'Start Log');
			INSERT INTO tmp_procedureLog (connectionId, logMessage) VALUES (connection_id( ), logMsg);
		END;

		INSERT INTO tmp_procedureLog (connectionId, logMessage) VALUES (connection_id( ), logMsg);
	END
//


DROP PROCEDURE IF EXISTS refreshProcedureLog //
CREATE PROCEDURE refreshProcedureLog( )
	BEGIN
		CALL procedureLog( 'Finish Log' );
		TRUNCATE TABLE procedureLog;
		INSERT INTO procedureLog
			SELECT
				*
			FROM tmp_procedureLog;
		DROP TABLE tmp_procedureLog;
	END
//

DELIMITER ;