-- http://blog.onefreevoice.com/
-- Gregory Haase
DELIMITER $$

DROP PROCEDURE IF EXISTS `mysql_experiments`.`rotate_archive_partitions`$$
CREATE PROCEDURE  `mysql_experiments`.`rotate_archive_partitions`(IN p_retention_days INT)
BEGIN
   /*
    * Script to archive table partitions. Creates new partitions and drops old ones
    * We select from information schema, and use a whole lot of dynamic sql.
    */

   DECLARE l_cutoff_date	   BIGINT(20);
   DECLARE l_table_name		   VARCHAR(100);
   DECLARE l_new_partitions    VARCHAR(200);
   DECLARE l_old_partitions    VARCHAR(100);
   DECLARE sql_make_partitions VARCHAR(1000);
   DECLARE sql_drop_partitions VARCHAR(1000);

   DECLARE done 			INT 		DEFAULT 0;
   DECLARE c_table_name CURSOR FOR SELECT a.table_name
                                     FROM information_schema.tables a,
                                          information_schema.columns b
                                    WHERE a.table_name = b.table_name
                                      AND a.engine = 'archive'
                                      AND b.column_name = 'date_string';
   DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

   -- if p_retention_days is null, we keep 7 days
   IF (p_retention_days IS NULL) THEN
     SET p_retention_days = 7;
   END IF;

   -- get the cutoff date - this is p_retention_days from midnight
   SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL p_retention_days DAY),'%Y%m%d')
     INTO l_cutoff_date;

   -- temporary table holds potential new partition names (date_string) and values less than clause (date_limit)
   DROP TEMPORARY TABLE IF EXISTS `mysql_experiments`.`tmp_partition_days`;
   CREATE TEMPORARY TABLE `mysql_experiments`.`tmp_partition_days` AS
      SELECT DATE_FORMAT(CURDATE(),'%Y%m%d') date_string,
             CONCAT(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 DAY),'%Y%m%d'),'0000') date_limit
       UNION
      SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 DAY),'%Y%m%d') date_string,
             CONCAT(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 2 DAY),'%Y%m%d'),'0000') date_limit
       UNION
      SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 2 DAY),'%Y%m%d') date_string,
             CONCAT(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 3 DAY),'%Y%m%d'),'0000') date_limit
       UNION
      SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 3 DAY),'%Y%m%d') date_string,
             CONCAT(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 4 DAY),'%Y%m%d'),'0000') date_limit;

   -- open cursor
   OPEN c_table_name;
   REPEAT
      FETCH c_table_name INTO l_table_name;
      IF NOT done THEN

      SELECT NULL INTO l_new_partitions;

      -- generate list of new partitions to create
      SELECT GROUP_CONCAT(CONCAT('PARTITION p',a.date_string,' VALUES LESS THAN (',a.date_limit,')'))
        INTO l_new_partitions
        FROM tmp_partition_days a
       WHERE a.date_string NOT IN (SELECT RIGHT(partition_name,8)
                                     FROM information_schema.partitions
                                    WHERE table_name = l_table_name)
       ORDER BY a.date_string ASC;

      IF (l_new_partitions IS NOT NULL) THEN

         -- create new partitions by reorganizing the last partition (always pEOW)
         SET sql_make_partitions = CONCAT('ALTER TABLE `',l_table_name,'` REORGANIZE PARTITION pEOW INTO (',l_new_partitions,', PARTITION pEOW VALUES LESS THAN MAXVALUE)');
         SET @sqlstatement = sql_make_partitions;
         PREPARE sqlquery FROM @sqlstatement;
         EXECUTE sqlquery;
         DEALLOCATE PREPARE sqlquery;

      END IF;


      -- find and drop partitions older than p_retention_days
      SELECT GROUP_CONCAT(partition_name)
        INTO l_old_partitions
        FROM information_schema.partitions
       WHERE RIGHT(partition_name,8) < l_cutoff_date
         AND partition_name <> 'pEOW'
         AND table_name = l_table_name;

      IF (l_old_partitions IS NOT NULL) THEN

         SET sql_drop_partitions = CONCAT('ALTER TABLE `',l_table_name,'` DROP PARTITION ',l_old_partitions);
         SET @sqlstatement = sql_drop_partitions;
         PREPARE sqlquery FROM @sqlstatement;
         EXECUTE sqlquery;
         DEALLOCATE PREPARE sqlquery;

      END IF;

      -- close cursor
      END IF;
      UNTIL done END REPEAT;
   CLOSE c_table_name;

END $$

DROP EVENT IF EXISTS `mysql_experiments`.`e_rotate_archive_partitions`$$
CREATE EVENT `mysql_experiments`.`e_rotate_archive_partitions`
   ON SCHEDULE
      EVERY 1 DAY
      STARTS curdate() + INTERVAL '8:07' HOUR_MINUTE
   DO
          call mysql_experiments.rotate_archive_partitions(7)$$


DELIMITER ;
