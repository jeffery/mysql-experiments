
CALL setupProcLog();

-- CALL createTableData('prune_test', 'myisam', 50000000, 1000);


CALL procLog('Start Pruning');
-- CALL pruneTableData(365, 'prune_test');
CALL pruneTableData(1200, 'sb_core_sbtrackerevents', 'EventTimestamp');
CALL procLog('Finish Pruning');
CALL cleanup('Done');
