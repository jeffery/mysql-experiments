CALL createTableData( 'prune_test', 'myisam', 5000000, 3652, '2003-01-01' );
CALL procedureLog( 'Start Pruning' );
CALL pruneTableData( 365, 'prune_test', 'createdDate' );
CALL procedureLog( 'Finish Pruning' );
CALL commitProcedureLog( );
