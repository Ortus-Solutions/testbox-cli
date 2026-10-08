/** One CLI consumer owns permanent CI logs or an interactive worker dashboard. */
component {

	struct function createEventHandlers(
		required any print,
		boolean verbose     = false,
		boolean interactive = false,
		any terminal
	){
		variables.output       = arguments.print;
		variables.verbose      = arguments.verbose;
		variables.interactive  = arguments.interactive;
		variables.workers      = [];
		variables.totalBundles = 0;
		variables.closed       = false;
		variables.cancelled    = false;
		variables.diagnostics  = [];
		variables.runStarted   = getTickCount();
		variables.phaseStarted = variables.runStarted;
		variables.phaseStopped = 0;
		variables.phase        = "Preparing shared environment";
		variables.phaseKind    = "prepare";
		variables.lockId       = "testbox-dashboard-" & createUUID();
		if ( variables.interactive ) {
			variables.terminal = arguments.terminal;
			variables.display  = createObject( "java", "org.jline.utils.Display" ).init( arguments.terminal, false );
		}
		var renderer = this;
		var handlers = {};
		for (
			var type in [
				"testRunStart",
				"runPhase",
				"bundleReady",
				"specStart",
				"workerStart",
				"bundleStart",
				"suiteStart",
				"specEnd",
				"bundleEnd",
				"workerEnd",
				"workerError",
				"runCancelling",
				"testRunEnd"
			]
		) {
			handlers[ type ] = makeHandler( renderer, type );
		}
		return handlers;
	}

	private function makeHandler(
		required any renderer,
		required string type
	){
		var consumer  = arguments.renderer;
		var eventType = arguments.type;
		return function( data ){
			consumer.handleEvent( eventType, data );
		};
	}

	function handleEvent(
		required string type,
		required struct data
	){
		lock name="#variables.lockId#" type="exclusive" timeout="#10#" {
			processEvent( arguments.type, arguments.data );
		}
	}

	private function processEvent(
		required string type,
		required struct data
	){
		if ( variables.closed ) {
			return;
		}
		if ( arguments.type == "testRunStart" ) {
			variables.totalBundles = data.totalBundles;
			for ( var i = 1; i <= data.workers; i++ ) {
				variables.workers.append( {
					"workerId"     : i,
					"totalBundles" : ( data.workerBundleCounts ?: [] ).len() >= i
					 ? data.workerBundleCounts[ i ]
					 : 0,
					"completedBundles" : 0,
					"passed"           : 0,
					"failed"           : 0,
					"errors"           : 0,
					"status"           : "Waiting for shared setup",
					"started"          : 0,
					"stopped"          : 0,
					"specStarted"      : 0,
					"activeSpecs"      : {},
					"currentPath"      : "",
					"bundles"          : {},
					"ended"            : false
				} );
			}
			if ( !variables.interactive ) {
				variables.output
					.line( "Running " & data.totalBundles & " bundles on " & data.workers & " workers." )
					.toConsole();
			}
			if ( variables.interactive ) {
				var renderer     = this;
				var generation   = variables.lockId;
				variables.future = application.wirebox
					.getTaskScheduler()
					.newSchedule( function(){
						renderer.tick( generation );
					} )
					.every( 120 )
					.start();
			}
		} else if ( arguments.type == "runPhase" ) {
			variables.phase     = data.message;
			variables.phaseKind = data.phase;
			if ( data.phase == "ready" ) {
				variables.phaseStopped = getTickCount();
				for ( var worker in variables.workers ) {
					if ( !worker.started ) {
						worker.status = "Waiting to start";
					}
				}
			} else if ( data.phase == "cleanup" ) {
				variables.phaseStarted = getTickCount();
				variables.phaseStopped = 0;
			}
			if ( !variables.interactive ) {
				variables.output.line( "[Coordinator] " & clean( data.message ) ).toConsole();
			}
		} else if ( arguments.type == "runCancelling" ) {
			variables.cancelled    = true;
			variables.phase        = data.message ?: "Stopping workers gracefully (30s maximum)";
			variables.phaseKind    = "cancelling";
			variables.phaseStarted = getTickCount();
			variables.phaseStopped = 0;
			if ( !variables.interactive ) {
				variables.output.line( variables.phase ).toConsole();
			}
			for ( var worker in variables.workers ) {
				if ( !worker.ended ) {
					worker.status = "Stopping";
				}
			}
		} else if ( arguments.type == "testRunEnd" ) {
			finishRun( data.results );
			return;
		} else if ( ( data.workerId ?: 0 ) > 0 && data.workerId <= variables.workers.len() ) {
			var worker = variables.workers[ data.workerId ];
			switch ( arguments.type ) {
				case "workerStart":
					worker.totalBundles = data.totalBundles;
					worker.started      = getTickCount();
					worker.status       = "Preparing isolated environment";
					logWorker(
						worker,
						"Preparing isolated environment"
					);
					break;
				case "bundleStart":
					worker.currentPath = data.path;
					getBundle( worker, data.path );
					worker.status = "Discovering specs";
					logWorker(
						worker,
						"Discovering specs in " & clean( data.path )
					);
					break;
				case "bundleReady":
					var bundle        = getBundle( worker, data.path );
					bundle.totalSpecs = data.totalSpecs;
					bundle.discovered = true;
					worker.status     = "Preparing bundle fixtures";
					logWorker(
						worker,
						"Preparing bundle fixtures in " & clean( data.path ) & " (" & data.totalSpecs & " " & plural(
							data.totalSpecs,
							"spec"
						) & ")"
					);
					break;
				case "specStart":
					worker.activeSpecs[ ( data.suiteId ?: "" ) & ":" & data.id ] = getTickCount();
					if ( !worker.specStarted ) {
						worker.specStarted = getTickCount();
					}
					worker.status = "Executing";
					break;
				case "suiteStart":
					var bundle        = getBundle( worker, data.bundlePath );
					bundle.totalSpecs = data.bundleTotalSpecs ?: bundle.totalSpecs;
					bundle.discovered = true;
					worker.status     = "Executing";
					break;
				case "specEnd":
					structDelete(
						worker.activeSpecs,
						( data.suiteId ?: "" ) & ":" & data.id
					);
					worker.specStarted = 0;
					for ( var specId in worker.activeSpecs ) {
						if ( !worker.specStarted || worker.activeSpecs[ specId ] < worker.specStarted ) {
							worker.specStarted = worker.activeSpecs[ specId ];
						}
					}
					var bundle = getBundle( worker, data.bundlePath );
					var id     = ( data.suiteId ?: "" ) & ":" & data.id;
					if ( !bundle.ended && !bundle.seen.keyExists( id ) ) {
						bundle.seen[ id ] = true;
						switch ( data.status ) {
							case "Passed":
								bundle.passed++;
								break;
							case "Failed":
								bundle.failed++;
								break;
							case "Error":
								bundle.errors++;
								break;
						}
						bundle.ran = bundle.passed + bundle.failed + bundle.errors;
						recount( worker );
						if ( variables.verbose || listFindNoCase( "Failed,Error", data.status ) ) {
							var message = clean( data.bundlePath ) & " / " & clean( data.name ) & ": " & clean(
								data.status
							);
							var detail = data.failMessage ?: data.errorMessage ?: "";
							if ( len( detail ) ) {
								message &= " - " & clean( detail );
							}
							if ( variables.interactive ) {
								variables.diagnostics.append( prefix( worker ) & message );
							} else {
								logWorker( worker, message );
							}
						}
					}
					break;
				case "bundleEnd":
					var bundle        = getBundle( worker, data.path );
					var alreadyEnded  = bundle.ended;
					bundle.passed     = data.totalPass;
					bundle.failed     = data.totalFail;
					bundle.errors     = data.totalError;
					bundle.totalSpecs = data.totalSpecs;
					bundle.ran        = bundle.passed + bundle.failed + bundle.errors;
					bundle.ended      = true;
					recount( worker );
					if ( !alreadyEnded ) {
						logWorker(
							worker,
							clean( data.path ) & " " & data.totalDuration & " ms - " & data.totalPass & " passed / " & data.totalFail & " failed / " & data.totalError & " errors"
						);
					}
					break;
				case "workerEnd":
					if ( data.complete || ( structKeyExists( data, "hasReport" ) && data.hasReport ) ) {
						worker.passed           = data.totalPass;
						worker.failed           = data.totalFail;
						worker.errors           = data.totalError;
						worker.completedBundles = max(
							worker.completedBundles,
							data.totalBundles
						);
					}
					worker.ended   = true;
					worker.stopped = getTickCount();
					worker.status  = data.complete ? "Completed" : ( variables.cancelled ? "Cancelled" : "Failed" );
					logWorker(
						worker,
						worker.status & " (" & data.seconds & "s)"
					);
					break;
				case "workerError":
					worker.status = variables.cancelled ? "Cancelled" : "Failed";
					var message   = prefix( worker ) & clean( data.message );
					if ( variables.interactive ) {
						variables.diagnostics.append( message );
					} else {
						variables.output.redLine( message ).toConsole();
					}
					break;
			}
		} else if ( arguments.type == "workerError" ) {
			var message = "[Coordinator] " & clean( data.message );
			if ( variables.interactive ) {
				variables.diagnostics.append( message );
			} else {
				variables.output.redLine( message ).toConsole();
			}
		}
		if ( variables.cancelled ) {
			for ( var worker in variables.workers ) {
				if ( !worker.ended ) {
					worker.status = "Stopping";
				}
			}
		}
		draw();
	}

	private struct function getBundle(
		required struct worker,
		required string path
	){
		var key = lCase( arguments.path );
		if ( !worker.bundles.keyExists( key ) ) {
			worker.bundles[ key ] = {
				"passed"     : 0,
				"failed"     : 0,
				"errors"     : 0,
				"ran"        : 0,
				"totalSpecs" : 0,
				"ended"      : false,
				"seen"       : {},
				"discovered" : false
			};
		}
		return worker.bundles[ key ];
	}

	private function recount( required struct worker ){
		worker.passed           = 0;
		worker.failed           = 0;
		worker.errors           = 0;
		worker.completedBundles = 0;
		for ( var key in worker.bundles ) {
			var bundle = worker.bundles[ key ];
			worker.passed += bundle.passed;
			worker.failed += bundle.failed;
			worker.errors += bundle.errors;
			if ( bundle.ended ) {
				worker.completedBundles++;
			}
		}
	}

	private string function clean( required string text ){
		return reReplace(
			arguments.text,
			"[\x00-\x1F\x7F]",
			"",
			"all"
		);
	}

	private string function prefix( required struct worker ){
		return "[Worker " & worker.workerId & "] [" & worker.completedBundles & "/" & worker.totalBundles & " " & plural(
			worker.totalBundles,
			"bundle"
		) & "] ";
	}

	private function logWorker(
		required struct worker,
		required string message
	){
		if ( !variables.interactive ) {
			variables.output.line( prefix( worker ) & message ).toConsole();
		}
	}

	array function getLines(){
		var completed = 0;
		var passed    = 0;
		var failed    = 0;
		var errors    = 0;
		for ( var worker in variables.workers ) {
			completed += worker.completedBundles;
			passed += worker.passed;
			failed += worker.failed;
			errors += worker.errors;
		}
		var lines = [
			completed & "/" & variables.totalBundles & " " & plural( variables.totalBundles, "bundle" ) & " completed | " & passed & " passed / " & failed & " failed / " & errors & " errored"
		];
		for ( var worker in variables.workers ) {
			var line = "[Worker " & worker.workerId & "] [" & worker.completedBundles & "/" & worker.totalBundles & " " & plural(
				worker.totalBundles,
				"bundle"
			) & "] (" & worker.passed & " passed / " & worker.failed & " failed / " & worker.errors & " " & plural(
				worker.errors,
				"error"
			) & "): ";
			var status = worker.status;
			if (
				listFind(
					"Executing,Discovering specs,Preparing bundle fixtures",
					status
				)
			) {
				var bundle = getBundle( worker, worker.currentPath );
				var suffix = status == "Discovering specs"
				 ? ""
				 : " (" & bundle.ran & "/" & ( bundle.discovered ? bundle.totalSpecs : "?" ) & " " & plural(
					bundle.totalSpecs,
					"spec"
				) & " ran)";
				var name = clean( worker.currentPath );
				if ( variables.interactive ) {
					var available = max(
						4,
						variables.terminal.getWidth() - len( line & status & " in " & suffix ) - 23
					);
					if ( len( name ) > available ) {
						name = "..." & right( name, available - 3 );
					}
				}
				status = ( status == "Executing" ? "Executing " : status & " in " ) & name & suffix;
			}
			lines.append( line & status );
		}
		return lines;
	}

	string function plural(
		required numeric count,
		required string word
	){
		return word & ( count == 1 ? "" : "s" );
	}

	string function elapsedSince(
		required numeric started,
		numeric stopped = 0,
		numeric now     = getTickCount()
	){
		return elapsed( ( arguments.stopped > 0 ? arguments.stopped : arguments.now ) - arguments.started );
	}

	string function elapsed( required numeric milliseconds ){
		var seconds = max( 0, int( milliseconds / 1000 ) );
		if ( seconds < 60 ) {
			return seconds & "s";
		}
		var tail = numberFormat( seconds % 60, "00" );
		if ( seconds < 3600 ) {
			return int( seconds / 60 ) & ":" & tail;
		}
		return int( seconds / 3600 ) & ":" & numberFormat( int( seconds / 60 ) % 60, "00" ) & ":" & tail;
	}

	private string function color(
		required string text,
		required numeric foreground,
		numeric background = -1
	){
		return chr( 27 ) & "[38;5;" & foreground & ( background >= 0 ? ";48;5;" & background : "" ) & "m" & text & chr(
			27
		) & "[0m";
	}

	private array function styledLines(){
		var now       = getTickCount();
		var frames    = [ "⠋", "⠙", "⠸", "⠴", "⠦", "⠇" ];
		var frame     = frames[ ( int( ( now - variables.runStarted ) / 120 ) % frames.len() ) + 1 ];
		var phaseIcon = listFind(
			"ready,completed",
			variables.phaseKind
		)
		 ? "✓"
		 : variables.phaseKind == "failed" ? "✕" : variables.phaseKind == "cancelled" ? "■" : frame;
		var phaseElapsed = elapsedSince(
			variables.phaseStarted,
			variables.phaseStopped,
			now
		);
		var phaseColor = variables.phaseKind == "failed"
		 ? 160
		 : listFind(
			"cancelling,cancelled",
			variables.phaseKind
		)
		 ? 130
		 : variables.phaseKind == "completed" ? 28 : 24;
		var lines = [
			color( phaseIcon, phaseColor ) & " " & color(
				" " & uCase( variables.phaseKind ) & " ",
				255,
				phaseColor
			) & " " & color( variables.phase, phaseColor ) & " " & color( "[" & phaseElapsed & "]", 242 )
		];
		var plain = getLines();
		lines.append(
			color(
				"[" & elapsed( now - variables.runStarted ) & "] ",
				242
			) & color( plain[ 1 ], 24 )
		);
		for ( var i = 1; i <= variables.workers.len(); i++ ) {
			var worker     = variables.workers[ i ];
			var stateColor = listFind( "Stopping,Cancelled", worker.status )
			 ? 172
			 : worker.status == "Failed" || ( worker.ended && worker.failed + worker.errors > 0 )
			 ? 160
			 : worker.ended ? 28 : 24;
			var icon = worker.status == "Cancelled"
			 ? "■"
			 : worker.status == "Failed" ? "✕" : worker.ended ? "✓" : worker.started ? frame : "·";
			var line = plain[ i + 1 ];
			line     = replace(
				line,
				"[Worker " & worker.workerId & "]",
				color(
					" Worker " & worker.workerId & " ",
					255,
					stateColor
				)
			);
			line = reReplace(
				line,
				"(\[[0-9]+/[0-9]+ bundles?\])",
				color( "\1", 23 ),
				"one"
			);
			line = replace(
				line,
				worker.passed & " passed",
				color(
					worker.passed & " passed",
					worker.passed ? 28 : 242
				)
			);
			line = replace(
				line,
				worker.failed & " failed",
				color(
					worker.failed & " failed",
					worker.failed ? 130 : 242
				)
			);
			line = replace(
				line,
				worker.errors & " " & plural( worker.errors, "error" ),
				color(
					worker.errors & " " & plural( worker.errors, "error" ),
					worker.errors ? 160 : 242
				)
			);
			var time = worker.started
			 ? elapsedSince( worker.started, worker.stopped, now )
			 : "waiting";
			var specTime = worker.specStarted && !worker.ended
			 ? " • spec " & elapsed( now - worker.specStarted )
			 : "";
			lines.append( color( icon, stateColor ) & " " & line & " " & color( "[" & time & specTime & "]", 242 ) );
		}
		return lines;
	}

	function tick( string generation = "" ){
		if ( len( arguments.generation ) && arguments.generation != variables.lockId ) {
			return;
		}
		lock name="#variables.lockId#" type="exclusive" timeout="#10#" {
			if ( !variables.closed ) {
				draw();
			}
		}
	}

	private function stopTicker(){
		if ( structKeyExists( variables, "future" ) ) {
			variables.future.cancel( false );
		}
	}

	private function draw(){
		if ( !variables.interactive || variables.closed || !variables.workers.len() ) {
			return;
		}
		var width  = max( 2, variables.terminal.getWidth() );
		var height = max( 2, variables.terminal.getHeight() );
		variables.display.resize( height, width );
		var lines = styledLines().map( function( line ){
			return createObject(
				"java",
				"org.jline.utils.AttributedString"
			).fromAnsi( line ).columnSubSequence( 0, width - 1 );
		} );
		lines.append(
			createObject(
				"java",
				"org.jline.utils.AttributedString"
			).init( "" )
		);
		variables.display.update(
			lines,
			javacast(
				"int",
				( lines.len() - 1 ) * ( width + 1 )
			)
		);
		variables.terminal.writer().flush();
	}

	function abort( string status = "Failed" ){
		lock name="#variables.lockId#" type="exclusive" timeout="#10#" {
			freeze( arguments.status );
		}
	}

	private function freeze( required string status ){
		if ( variables.closed ) {
			return;
		}
		for ( var worker in variables.workers ) {
			if ( !worker.ended ) {
				worker.status = arguments.status;
			}
		}
		variables.phaseKind    = lCase( arguments.status );
		variables.phase        = arguments.status;
		variables.phaseStarted = variables.runStarted;
		variables.phaseStopped = getTickCount();
		draw();
		variables.closed = true;
		stopTicker();
		printDiagnostics();
	}

	private function printDiagnostics(){
		for ( var message in variables.diagnostics ) {
			variables.output.line( message );
		}
		variables.output.toConsole();
	}

	private function finishRun( required struct results ){
		variables.cancelled = results.parallel.cancelled;
		for ( var stats in results.parallel.workerStats ) {
			var worker = variables.workers[ stats.workerId ];
			if ( structKeyExists( stats.report, "bundleStats" ) ) {
				worker.completedBundles = max(
					worker.completedBundles,
					stats.report.bundleStats.len()
				);
				worker.passed = stats.report.totalPass ?: 0;
				worker.failed = stats.report.totalFail ?: 0;
				worker.errors = stats.report.totalError ?: 0;
			}
			worker.status = stats.complete ? "Completed" : ( variables.cancelled ? "Cancelled" : "Failed" );
			worker.ended  = true;
		}
		for ( var worker in variables.workers ) {
			if ( !worker.ended ) {
				worker.status = variables.cancelled ? "Cancelled" : "Failed";
			}
			if ( worker.stopped == 0 ) {
				worker.stopped = getTickCount();
			}
		}
		variables.phaseKind = variables.cancelled
		 ? "cancelled"
		 : ( results.passed ?: false ) ? "completed" : "failed";
		variables.phase = variables.cancelled
		 ? "Cancelled"
		 : ( results.passed ?: false ) ? "Completed" : "Completed with failures";
		variables.phaseStarted = variables.runStarted;
		variables.phaseStopped = getTickCount();
		draw();
		variables.closed = true;
		stopTicker();
		printDiagnostics();
		renderTimings( variables.output, results );
		variables.output.line( "Parallel run finished; combined results follow." ).toConsole();
	}

	string function duration( required numeric milliseconds ){
		var seconds = int( max( 0, arguments.milliseconds ) / 1000 );
		return numberFormat( int( seconds / 3600 ), "00" ) & ":" & numberFormat( int( seconds / 60 ) % 60, "00" ) & ":" & numberFormat(
			seconds % 60,
			"00"
		);
	}

	function renderTimings(
		required any print,
		required struct results
	){
		var parallel = arguments.results.parallel;
		arguments.print.line().line( "Worker timings (HH:MM:SS):" );
		var rows    = [];
		var workers = parallel.workerStats.map( function( worker ){
			return worker;
		} );
		workers.sort( function( a, b ){
			return a.workerId - b.workerId;
		} );
		for ( var worker in workers ) {
			var elapsed   = worker.wallMilliseconds / 1000;
			var execution = worker.executionSeconds ?: javacast( "null", "" );
			var cleanup   = worker.cleanupSeconds ?: javacast( "null", "" );
			var other     = !isNull( execution ) && !isNull( cleanup )
			 ? max( 0, elapsed - execution - cleanup )
			 : javacast( "null", "" );
			rows.append( {
				"worker"    : worker.workerId,
				"bundles"   : worker.assignedBundles,
				"specs"     : worker.report.totalSpecs ?: 0,
				"elapsed"   : duration( worker.wallMilliseconds ),
				"execution" : isNull( execution ) ? "n/a" : duration( execution * 1000 ),
				"cleanup"   : isNull( cleanup ) ? "n/a" : duration( cleanup * 1000 ),
				"other"     : isNull( other ) ? "n/a" : duration( other * 1000 ),
				"status"    : worker.complete ? "Complete" : "Incomplete"
			} );
		}
		arguments.print.table(
			rows,
			"worker,bundles,specs,elapsed,execution,cleanup,other,status",
			"Worker,Bundles,Specs,Elapsed,Test request,Cleanup,Other,Status"
		);
		var timing = parallel.timing;
		arguments.print.line(
			"Run elapsed: " & duration( parallel.wallMilliseconds ) & "; " & numberFormat(
				timing.specsPerSecond,
				"0.00"
			) & " specs/s; shared preparation: " & duration( timing.preparationMilliseconds ) & "."
		);
		if ( timing.reportedWorkers ) {
			arguments.print.line(
				"Worker elapsed range: " & duration( timing.fastestWorkerMilliseconds ) & "–" & duration(
					timing.slowestWorkerMilliseconds
				) & "; spread: " & duration( timing.workerSpreadMilliseconds ) & "."
			);
		}
		arguments.print.toConsole();
	}

}
