DELIMITER //

DROP PROCEDURE IF EXISTS setupProcLog //
CREATE PROCEDURE setupProcLog()
  BEGIN
    DECLARE proclog_exists INT DEFAULT 0;

/*
 * check if proclog is existing. This check seems redundant, but
 * simply relying on 'create table if not exists' is not enough because
 * a warning is thrown which will be caught by your exception handler
*/
    SELECT
      count(*)
    INTO proclog_exists
    FROM information_schema.tables
    WHERE table_schema = database() AND table_name = 'proclog';

    IF proclog_exists = 0
    THEN
      CREATE TABLE IF NOT EXISTS proclog (
        id            INT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
        entrytime     DATETIME,
        connection_id INT             NOT NULL DEFAULT 0,
        msg           VARCHAR(512),
        PRIMARY KEY (id)
      );
    END IF;

/*
 * temp table is not checked in information_schema because it is a temp
 * table
 */
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_proclog (
      id            INT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
      entrytime     TIMESTAMP,
      connection_id INT             NOT NULL DEFAULT 0,
      msg           VARCHAR(512),
      PRIMARY KEY (id)
    )
      ENGINE = MEMORY;

  END //

DROP PROCEDURE IF EXISTS procLog //

CREATE PROCEDURE procLog(IN logMsg VARCHAR(512))
  BEGIN
    DECLARE CONTINUE HANDLER FOR 1146 -- Table not found
    BEGIN
      CALL setupProcLog();
      INSERT INTO tmp_proclog (connection_id, msg) VALUES (connection_id(), 'reset tmp table');
      INSERT INTO tmp_proclog (connection_id, msg) VALUES (connection_id(), logMsg);
    END;

    INSERT INTO tmp_proclog (connection_id, msg) VALUES (connection_id(), logMsg);
  END //

DROP PROCEDURE IF EXISTS cleanup //
CREATE PROCEDURE cleanup(IN logMsg VARCHAR(512))
  BEGIN
    CALL procLog(concat("cleanup() ", ifnull(logMsg, '')));
    TRUNCATE TABLE proclog;
    INSERT INTO proclog SELECT
                          *
                        FROM tmp_proclog;
    DROP TABLE tmp_proclog;
  END //

DELIMITER ;