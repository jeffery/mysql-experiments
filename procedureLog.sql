DELIMITER //

DROP PROCEDURE IF EXISTS procedureLog //
CREATE PROCEDURE procedureLog( IN logMsg VARCHAR(20000) )
	BEGIN
		DECLARE connectionIdentity INT DEFAULT 0;
		DECLARE checkConnectionId INT DEFAULT 0;

		DECLARE CONTINUE HANDLER FOR SQLSTATE '42S02' -- Table not found
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
					logMessage   VARCHAR(20000),
					PRIMARY KEY (id)
				);
			END IF;
		END;

		SELECT
			count( * )
		INTO checkConnectionId
		FROM procedureLog
		WHERE connectionId != CONNECTION_ID( );

		IF checkConnectionId > 0
		THEN
			TRUNCATE TABLE procedureLog;
		END IF;

		INSERT INTO procedureLog (logTime, connectionId, logMessage) VALUES ( NOW( ), CONNECTION_ID( ), logMsg );
	END
//

DELIMITER ;