DELIMITER //

/*
 * Script to keep at least p_retention_days worth of data in the mysql tables.
 * We select from information schema, and use a whole lot of dynamic sql.
 */
DROP PROCEDURE IF EXISTS pruneTableData //
CREATE PROCEDURE pruneTableData(IN p_retention_days INT, IN tableName CHAR(64), IN columnName CHAR(64))
  COMMENT 'Procedure to Prune Database table by a calculated data column'
  BEGIN

    DECLARE l_cutoff_date CHAR(10);
    DECLARE l_table_name VARCHAR(100);
    DECLARE sql_create_table VARCHAR(1000);
    DECLARE sql_rename_table VARCHAR(1000);
    DECLARE sql_reload_table VARCHAR(1000);
    DECLARE sql_drop_table VARCHAR(1000);

    DECLARE done INT DEFAULT 0;
    DECLARE c_table_name CURSOR FOR SELECT
                                      table_name
                                    FROM information_schema.tables
                                    WHERE table_name = tableName;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

    CALL proclog(CONCAT('Pruning Table: ', tableName, ' for Database ', DATABASE()));

-- if p_retention_days is null, we keep 365 days
    IF (p_retention_days IS NULL)
    THEN
      SET p_retention_days = 365;
    END IF;

    CALL procLog(CONCAT('Retention Days: ', p_retention_days));

-- get the cutoff date - this is p_retention_days from midnight
    SELECT
      DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL p_retention_days DAY), '%Y-%m-%d')
    INTO l_cutoff_date;

    CALL procLog(CONCAT('Cut Off Date: ', l_cutoff_date));

-- OPEN CURSOR
    OPEN c_table_name;
    REPEAT
      FETCH c_table_name
      INTO l_table_name;
    IF NOT done
    THEN

-- CREATE TABLE LIKE SOURCE TABLE
      SET sql_create_table = CONCAT('CREATE TABLE IF NOT EXISTS `new_', l_table_name, '` LIKE `', l_table_name, '`');
-- SELECT sql_create_table;
      SET @sqlstatement = sql_create_table;
      PREPARE sqlquery FROM @sqlstatement;
      EXECUTE sqlquery;
      DEALLOCATE PREPARE sqlquery;
      CALL procLog(CONCAT('Create New Table: ', sql_create_table));

-- RENAME TABLES
      SET sql_rename_table = CONCAT('RENAME TABLE `', l_table_name, '` TO `old_', l_table_name, '`, `new_', l_table_name, '` TO `', l_table_name, '`');
-- SELECT sql_rename_table;
      SET @sqlstatement = sql_rename_table;
      PREPARE sqlquery FROM @sqlstatement;
      EXECUTE sqlquery;
      DEALLOCATE PREPARE sqlquery;
      CALL procLog(CONCAT('Rename Tables: ', sql_rename_table));

-- COPY LAST 'n' DAYS DATA BACK INTO THE SOURCE TABLE
      SET sql_reload_table = CONCAT('INSERT INTO `', l_table_name, '` SELECT * FROM `old_', l_table_name, '` WHERE ', columnName ,' >= ', "'", l_cutoff_date, "'");
-- SELECT sql_reload_table;
      SET @sqlstatement = sql_reload_table;
      PREPARE sqlquery FROM @sqlstatement;
      EXECUTE sqlquery;
      DEALLOCATE PREPARE sqlquery;
      CALL procLog(CONCAT('Reload Tables: ', sql_reload_table));

-- DROP NEW TABLE
      SET sql_drop_table = CONCAT('DROP TABLE IF EXISTS `old_', l_table_name, '`');
-- SELECT sql_drop_table;
      SET @sqlstatement = sql_drop_table;
      PREPARE sqlquery FROM @sqlstatement;
      EXECUTE sqlquery;
      DEALLOCATE PREPARE sqlquery;
      CALL procLog(CONCAT('Cleanup Tables: ', sql_drop_table));

-- CLOSE CURSOR
    END IF;
    UNTIL done END REPEAT;
    CLOSE c_table_name;

  END //

DELIMITER ;