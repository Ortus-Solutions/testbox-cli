/** CommandBox-only renderer contracts and optional terminal preview; no application tests. */
component {

	function run( boolean interactive = false ){
		variables.fileSystemUtil.createMapping(
			"/testboxCLI",
			variables.fileSystemUtil.resolvePath( "." )
		);
		variables.fileSystemUtil.createMapping(
			"/testboxCLIOutputFixtures",
			getDirectoryFromPath( getCurrentTemplatePath() )
		);
		var output   = interactive ? variables.print : new testboxCLIOutputFixtures.OutputCapture();
		var renderer = new testboxCLI.models.ParallelStreamingRenderer();
		if (
			renderer.elapsedSince( 1000, 0, 21000 ) !=
			"20s" ||
			renderer.elapsedSince( 1000, 6000, 21000 ) !=
			"5s"
		) {
			throw( message = "Running clocks must advance with zero stop time; completed clocks must stay frozen" );
		}
		if (
			renderer.duration( 59000 ) != "00:00:59" || renderer.duration( 61000 ) != "00:01:01" ||
			renderer.duration( 3661000 ) != "01:01:01"
		) {
			throw( message = "Timing table duration rollover mismatch" );
		}
		if (
			renderer.elapsed( 59000 ) != "59s" || renderer.elapsed( 61000 ) != "1:01" ||
			renderer.elapsed( 3661000 ) != "1:01:01"
		) {
			throw( message = "Elapsed clock rollover mismatch" );
		}
		var handlers = renderer.createEventHandlers(
			output,
			false,
			interactive,
			variables.shell.getReader().getTerminal()
		);
		var send = function( type, data ){
			handlers[ type ]( data );
		};
		send(
			"testRunStart",
			{
				"totalBundles"       : 3,
				"workers"            : 2,
				"workerBundleCounts" : [ 2, 1 ]
			}
		);
		send(
			"runPhase",
			{
				"phase"   : "prepare",
				"message" : "Preparing shared engine modules"
			}
		);
		send(
			"runPhase",
			{
				"phase"   : "ready",
				"message" : "Shared setup ready"
			}
		);
		if ( interactive ) {
			sleep( 500 );
		}
		send(
			"workerStart",
			{ "workerId" : 1, "totalBundles" : 2 }
		);
		send(
			"workerStart",
			{ "workerId" : 2, "totalBundles" : 1 }
		);
		send(
			"bundleStart",
			{
				"workerId" : 1,
				"path"     : "tests.BundleA"
			}
		);
		send(
			"bundleReady",
			{
				"workerId"   : 1,
				"path"       : "tests.BundleA",
				"totalSpecs" : 2
			}
		);
		if ( interactive ) {
			sleep( 500 );
		}
		send(
			"suiteStart",
			{
				"workerId"         : 1,
				"bundlePath"       : "tests.BundleA",
				"bundleTotalSpecs" : 2
			}
		);
		send(
			"bundleStart",
			{
				"workerId" : 2,
				"path"     : "tests.BundleB"
			}
		);
		send(
			"suiteStart",
			{
				"workerId"         : 2,
				"bundlePath"       : "tests.BundleB",
				"bundleTotalSpecs" : 1
			}
		);
		var spec = {
			"workerId"   : 1,
			"bundlePath" : "tests.BundleA",
			"suiteId"    : "A",
			"id"         : "one",
			"name"       : "First",
			"status"     : "Passed"
		};
		send( "specStart", spec );
		if ( interactive ) {
			sleep( 1200 );
		}
		send( "specEnd", spec );
		send( "specEnd", spec );
		assertLine(
			renderer.getLines()[ 1 ],
			"0/3 bundles completed | 1 passed / 0 failed / 0 errored"
		);
		send(
			"specEnd",
			{
				"workerId"     : 2,
				"bundlePath"   : "tests.BundleB",
				"suiteId"      : "B",
				"id"           : "two",
				"name"         : "Second",
				"status"       : "Error",
				"errorMessage" : "Synthetic error"
			}
		);
		send(
			"specEnd",
			{
				"workerId"    : 1,
				"bundlePath"  : "tests.BundleA",
				"suiteId"     : "A",
				"id"          : "three",
				"name"        : "Third",
				"status"      : "Failed",
				"failMessage" : "Synthetic failure"
			}
		);
		if ( !interactive ) {
			assertLine(
				renderer.getLines()[ 2 ],
				"[Worker 1] [0/2 bundles] (1 passed / 1 failed / 0 errors): Executing tests.BundleA (2/2 specs ran)"
			);
		}
		send(
			"bundleEnd",
			{
				"workerId"      : 1,
				"path"          : "tests.BundleA",
				"totalSpecs"    : 2,
				"totalPass"     : 1,
				"totalFail"     : 1,
				"totalError"    : 0,
				"totalDuration" : 42
			}
		);
		send(
			"bundleEnd",
			{
				"workerId"      : 2,
				"path"          : "tests.BundleB",
				"totalSpecs"    : 1,
				"totalPass"     : 0,
				"totalFail"     : 0,
				"totalError"    : 1,
				"totalDuration" : 17
			}
		);
		assertLine(
			renderer.getLines()[ 1 ],
			"2/3 bundles completed | 1 passed / 1 failed / 1 errored"
		);
		send(
			"bundleStart",
			{
				"workerId" : 1,
				"path"     : "tests.BundleC"
			}
		);
		send(
			"suiteStart",
			{
				"workerId"         : 1,
				"bundlePath"       : "tests.BundleC",
				"bundleTotalSpecs" : 1
			}
		);
		send(
			"specEnd",
			{
				"workerId"   : 1,
				"bundlePath" : "tests.BundleC",
				"suiteId"    : "C",
				"id"         : "four",
				"name"       : "Fourth",
				"status"     : "Passed"
			}
		);
		send(
			"bundleEnd",
			{
				"workerId"      : 1,
				"path"          : "tests.BundleC",
				"totalSpecs"    : 1,
				"totalPass"     : 1,
				"totalFail"     : 0,
				"totalError"    : 0,
				"totalDuration" : 9
			}
		);
		send(
			"workerEnd",
			{
				"workerId"     : 1,
				"complete"     : true,
				"totalBundles" : 2,
				"totalPass"    : 2,
				"totalFail"    : 1,
				"totalError"   : 0,
				"seconds"      : .08
			}
		);
		send(
			"workerEnd",
			{
				"workerId"     : 2,
				"complete"     : true,
				"totalBundles" : 1,
				"totalPass"    : 0,
				"totalFail"    : 0,
				"totalError"   : 1,
				"seconds"      : .03
			}
		);
		var results = {
			"totalPass"  : 2,
			"totalFail"  : 1,
			"totalError" : 1,
			"totalSpecs" : 4,
			"parallel"   : {
				"cancelled"        : false,
				"wallMilliseconds" : 100,
				"workerStats"      : [
					{
						"workerId"         : 1,
						"assignedBundles"  : 2,
						"wallMilliseconds" : 80,
						"executionSeconds" : .05,
						"cleanupSeconds"   : .01,
						"complete"         : true,
						"report"           : {
							"bundleStats" : [ {}, {} ],
							"totalSpecs"  : 3,
							"totalPass"   : 2,
							"totalFail"   : 1,
							"totalError"  : 0
						}
					},
					{
						"workerId"         : 2,
						"assignedBundles"  : 1,
						"wallMilliseconds" : 30,
						"executionSeconds" : .017,
						"cleanupSeconds"   : .005,
						"complete"         : true,
						"report"           : {
							"bundleStats" : [ {} ],
							"totalSpecs"  : 1,
							"totalPass"   : 0,
							"totalFail"   : 0,
							"totalError"  : 1
						}
					}
				],
				"timing" : {
					"specsPerSecond"            : 40,
					"preparationMilliseconds"   : 10,
					"reportedWorkers"           : 2,
					"fastestWorkerMilliseconds" : 30,
					"slowestWorkerMilliseconds" : 80,
					"workerSpreadMilliseconds"  : 50
				}
			}
		};
		send(
			"testRunEnd",
			{ "results" : results }
		);
		if (
			!interactive &&
			(
				output.tableData.len() != 2 || output.tableData[ 1 ].worker != 1 ||
				output.tableData[ 1 ].elapsed != "00:00:00" ||
				output.tableHeaders != "Worker,Bundles,Specs,Elapsed,Test request,Cleanup,Other,Status"
			)
		) {
			throw( message = "Native timing table data mismatch" );
		}
		assertLine(
			renderer.getLines()[ 2 ],
			"[Worker 1] [2/2 bundles] (2 passed / 1 failed / 0 errors): Completed"
		);
		if ( !interactive ) {
			if ( !output.lines.find( "[Worker 1] [1/2 bundles] tests.BundleA 42 ms - 1 passed / 1 failed / 0 errors" ) ) {
				throw( message = "Permanent bundle log mismatch" );
			}
			variables.print.line(
				"Verified permanent logs, interleaved cumulative counts, duplicate events, and final completed rows."
			);
			// Cancellation and missing worker reports preserve observed progress.
			handlers = renderer.createEventHandlers( output );
			send(
				"testRunStart",
				{
					"totalBundles"       : 1,
					"workers"            : 1,
					"workerBundleCounts" : [ 1 ]
				}
			);
			send(
				"bundleStart",
				{
					"workerId" : 1,
					"path"     : "tests.Partial"
				}
			);
			send(
				"specEnd",
				{
					"workerId"   : 1,
					"bundlePath" : "tests.Partial",
					"suiteId"    : "S",
					"id"         : "P",
					"name"       : "Partial",
					"status"     : "Passed"
				}
			);
			send( "runCancelling", {} );
			send(
				"specStart",
				{
					"workerId" : 1,
					"suiteId"  : "S",
					"id"       : "late"
				}
			);
			if (
				!find(
					": Stopping",
					renderer.getLines()[ 2 ]
				)
			) {
				throw( message = "Late worker events must not replace the stopping status" );
			}
			send(
				"workerEnd",
				{
					"workerId"     : 1,
					"complete"     : false,
					"hasReport"    : false,
					"totalBundles" : 0,
					"totalPass"    : 0,
					"totalFail"    : 0,
					"totalError"   : 0,
					"seconds"      : 1
				}
			);
			var cancelledResults                             = duplicate( results );
			cancelledResults.parallel.cancelled              = true;
			cancelledResults.parallel.workerStats            = [];
			cancelledResults.parallel.timing.reportedWorkers = 0;
			send(
				"testRunEnd",
				{ "results" : cancelledResults }
			);
			assertLine(
				renderer.getLines()[ 2 ],
				"[Worker 1] [0/1 bundle] (1 passed / 0 failed / 0 errors): Cancelled"
			);
			handlers = renderer.createEventHandlers( output );
			send(
				"testRunStart",
				{
					"totalBundles"       : 1,
					"workers"            : 1,
					"workerBundleCounts" : [ 1 ]
				}
			);
			send(
				"workerError",
				{
					"workerId" : 1,
					"message"  : "Startup failure"
				}
			);
			renderer.abort();
			assertLine(
				renderer.getLines()[ 2 ],
				"[Worker 1] [0/1 bundle] (0 passed / 0 failed / 0 errors): Failed"
			);
			variables.print.line( "Verified cancellation and startup failure rows retain actual progress." );
		}
	}

	private function assertLine(
		required string actual,
		required string expected
	){
		if ( actual != expected ) {
			throw(
				message = "Output mismatch",
				detail  = "Expected: #expected#; Actual: #actual#"
			);
		}
	}

}
