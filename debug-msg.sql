DELIMITER $$

DROP PROCEDURE IF EXISTS `debug_msg`$$
DROP PROCEDURE IF EXISTS `test_procedure`$$

CREATE PROCEDURE debug_msg(enabled INTEGER, msg VARCHAR(255))
BEGIN
  IF enabled THEN BEGIN
    select concat("** ", msg) AS '** DEBUG:';
  END; END IF;
END $$

CREATE PROCEDURE test_procedure(arg1 INTEGER, arg2 INTEGER)
BEGIN
  SET @enabled = TRUE;

  call debug_msg(@enabled, "my first debug message");
  call debug_msg(@enabled, (select concat_ws('',"arg1:", arg1)));
  call debug_msg(TRUE, "This message will show up no matter what the value of enabled is");
  call debug_msg(FALSE, "This message will never show up");
END $$

DELIMITER ;

CALL test_procedure(1,2)