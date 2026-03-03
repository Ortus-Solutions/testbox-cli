/**
 * Renders streaming test results to the CLI in real-time
 * Works with SSE events from TestBox's StreamingRunner
 */
component singleton {

	property name="progressBarGeneric" inject="progressBarGeneric";
	property name="shell" inject="shell";
	property name="print" inject="Print";

	processingdirective pageEncoding="UTF-8";

	variables.COLOR = {
		PASS    : "SpringGreen1",
		SKIP    : "gray",
		ERROR   : "boldRed",
		FAIL    : "red",
		RUNNING : "yellow"
	};

	// ANSI escape codes for terminal control
	variables.ANSI = {
		"CLEAR_LINE"      : chr( 27 ) & "[2K",  // Clear entire line
		"CARRIAGE_RETURN" : chr( 13 ),          // Move cursor to beginning of line
		"CURSOR_UP"       : chr( 27 ) & "[1A"   // Move cursor up one line
	};

	// Track state during streaming
	variables.state = {
		"currentBundle"    : "",
		"currentSuite"     : "",
		"suiteStack"       : [],
		"totalBundles"     : 0,
		"completedBundles" : 0,
		"totalSpecs"       : 0,
		"passedSpecs"      : 0,
		"failedSpecs"      : 0,
		"errorSpecs"       : 0,
		"skippedSpecs"     : 0,
		"hasRunningSpec"   : false,  // Track if we have a running spec line to overwrite
		"runningSpecLine"  : ""      // Track current running spec line content
	};

	/**
	 * Reset state for a new test run
	 */
	function resetState(){
		variables.state = {
			"currentBundle"    : "",
			"currentSuite"     : "",
			"suiteStack"       : [],
			"totalBundles"     : 0,
			"completedBundles" : 0,
			"totalSpecs"       : 0,
			"passedSpecs"      : 0,
			"failedSpecs"      : 0,
			"errorSpecs"       : 0,
			"skippedSpecs"     : 0,
			"hasRunningSpec"   : false,
			"runningSpecLine"  : ""
		};
		return this;
	}

	/**
	 * Create event handlers for SSE streaming
	 *
	 * @print   The print buffer from CommandBox
	 * @verbose Whether to show passing specs
	 *
	 * @return Struct of event handler closures
	 */
	struct function createEventHandlers( required print, boolean verbose = false ){
		var renderer = this;
		var p        = arguments.print;
		var v        = arguments.verbose;
		var sh       = variables.shell;
		var pr       = variables.print;  // Print helper for getting colored strings
		
		// Get terminal for real-time output
		var terminal = javacast( "null", "" );
		var termWriter = javacast( "null", "" );
		try {
			if ( !isNull( sh ) && !isNull( sh.getReader() ) ) {
				terminal = sh.getReader().getTerminal();
				termWriter = terminal.writer();
			}
		} catch ( any e ) {
			// Terminal not available, will fall back to print buffer
		}

		// ANSI codes for terminal control (needed in closures)
		var ANSI_CR = variables.ANSI.CARRIAGE_RETURN;
		var ANSI_CLEAR = variables.ANSI.CLEAR_LINE;

		return {
			"testRunStart" : function( data ){
				renderer.resetState();
				variables.state.totalBundles = data.totalBundles ?: 0;
				p.line().boldCyanLine( "Starting test run with #variables.state.totalBundles# bundle(s)..." ).toConsole();
			},
			"bundleStart" : function( data ){
				variables.state.currentBundle = data.name ?: data.path ?: "Unknown Bundle";
				variables.state.suiteStack    = [];
				p.line().boldWhiteLine( "Bundle: #variables.state.currentBundle#" ).toConsole();
			},
			"bundleEnd" : function( data ){
				variables.state.completedBundles++;
				var color = renderer.getAggregatedColor( data.totalError ?: 0, data.totalFail ?: 0, 0 );
				p.line(
						"  [Passed: #data.totalPass ?: 0#] [Failed: #data.totalFail ?: 0#] [Errors: #data.totalError ?: 0#] [Skipped: #data.totalSkipped ?: 0#] (#data.totalDuration ?: 0# ms)",
						color
					)
					.toConsole();
			},
			"suiteStart" : function( data ){
				variables.state.suiteStack.append( data.name ?: "Unknown Suite" );
				variables.state.currentSuite = data.name ?: "Unknown Suite";
				var indent                   = repeatString( "  ", variables.state.suiteStack.len() );
				if ( v ) {
					p.line( "#indent##data.name ?: 'Unknown Suite'#", "white" ).toConsole();
				}
			},
			"suiteEnd" : function( data ){
				if ( variables.state.suiteStack.len() ) {
					variables.state.suiteStack.deleteAt( variables.state.suiteStack.len() );
				}
				if ( variables.state.suiteStack.len() ) {
					variables.state.currentSuite = variables.state.suiteStack[ variables.state.suiteStack.len() ];
				} else {
					variables.state.currentSuite = "";
				}
			},
			"specStart" : function( data ){
				variables.state.totalSpecs++;
				var name   = data.displayName ?: data.name ?: "Unknown Spec";
				var indent = repeatString( "  ", variables.state.suiteStack.len() + 1 );
				
				// Show running spec indicator
				// Use raw terminal writer for proper ANSI code handling (bypasses AttributedString)
				if ( !isNull( termWriter ) && !isNull( pr ) ) {
					var runningText = pr.yellowText( "#indent#» #name#..." );
					termWriter.print( runningText );
					termWriter.flush();
					// Also flush the terminal itself to force immediate display
					if ( !isNull( terminal ) ) {
						terminal.flush();
					}
					variables.state.hasRunningSpec = true;
					variables.state.runningSpecLine = runningText;
				} else {
					// Fallback to print buffer for testing
					p.text( "#indent#» #name#...", variables.COLOR.RUNNING ).toConsole();
					variables.state.hasRunningSpec = true;
				}
			},
			"specEnd" : function( data ){
				var status = data.status ?: "unknown";
				var name   = data.displayName ?: data.name ?: "Unknown Spec";
				var indent = repeatString( "  ", variables.state.suiteStack.len() + 1 );

				// Update counters
				switch ( status ) {
					case "passed":
						variables.state.passedSpecs++;
						break;
					case "failed":
						variables.state.failedSpecs++;
						break;
					case "error":
						variables.state.errorSpecs++;
						break;
					case "skipped":
						variables.state.skippedSpecs++;
						break;
				}

				// Clear the running spec line
				if ( variables.state.hasRunningSpec ) {
					if ( !isNull( termWriter ) ) {
						// Move to beginning of line and clear it
						termWriter.print( ANSI_CR & ANSI_CLEAR );
						termWriter.flush();
					} else {
						// Fallback for testing
						p.text( ANSI_CR & ANSI_CLEAR ).toConsole();
					}
					variables.state.hasRunningSpec = false;
					variables.state.runningSpecLine = "";
				}

				// For passed specs: line is cleared, nothing printed (already overwritten)
				// For failed/error/skipped: print the result (it persists)
				// If verbose: always print the result
				if ( status != "passed" || v ) {
					var indicator = renderer.getIndicator( status );
					var color     = renderer.getStatusColor( status );
					p.line( "#indent##indicator##name# (#data.totalDuration ?: 0# ms)", color ).toConsole();

					// Show failure details
					if ( status == "failed" && len( data.failMessage ?: "" ) ) {
						p.line( "#indent#  -> Failure: #data.failMessage#", variables.COLOR.FAIL ).toConsole();
					}

					// Show error details
					if ( status == "error" && structKeyExists( data, "error" ) && isStruct( data.error ) ) {
						p.line( "#indent#  -> Error: #data.error.message ?: 'Unknown error'#", variables.COLOR.ERROR )
							.toConsole();
					}
				}
			},
			"testRunEnd" : function( data ){
				// Final summary is handled by the main renderer using the full results
				p.line().boldGreenLine( "Test run complete!" ).toConsole();
			}
		};
	}

	/**
	 * Get status indicator character
	 */
	function getIndicator( required string status ){
		switch ( arguments.status ) {
			case "error":
				return "!! ";
			case "failed":
				return "X ";
			case "skipped":
				return "- ";
			case "passed":
				return "√ ";
			default:
				return "? ";
		}
	}

	/**
	 * Get color for a status
	 */
	function getStatusColor( required string status ){
		switch ( arguments.status ) {
			case "error":
				return variables.COLOR.ERROR;
			case "failed":
				return variables.COLOR.FAIL;
			case "skipped":
				return variables.COLOR.SKIP;
			case "passed":
				return variables.COLOR.PASS;
			default:
				return "white";
		}
	}

	/**
	 * Get aggregate color based on error/failure counts
	 */
	function getAggregatedColor( errors = 0, failures = 0, skips = 0 ){
		if ( arguments.errors ) {
			return variables.COLOR.ERROR;
		} else if ( arguments.failures ) {
			return variables.COLOR.FAIL;
		} else if ( arguments.skips ) {
			return variables.COLOR.SKIP;
		} else {
			return variables.COLOR.PASS;
		}
	}

}
