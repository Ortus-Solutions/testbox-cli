/**
 *********************************************************************************
 * Copyright Since 2014 CommandBox by Ortus Solutions, Corp
 * www.coldbox.org | www.ortussolutions.com
 ********************************************************************************
 * @author Brad Wood, Luis Majano, Denny Valliant
 *
 * I render TestBox data out for the CLI
 */
component {

	property name="JSONPrettyPrint" inject="provider:JSONPrettyPrint";
	property name="JSONService"     inject="JSONService";

	processingdirective pageEncoding="UTF-8";

	variables.HEADER_CELL_CHARS = 7;
	variables.COLOR             = {
		PASS  : "SpringGreen1",
		SKIP  : "blue",
		ERROR : "boldRed",
		FAIL  : "red"
	};
	variables.MAX_STACKTRACES = 5;

	/**
	 * @print a print buffer to use
	 * @testData test results from TestBox
	 * @verbose Display information about passing and skipped specs
	 */
	function render( print, testData, verbose ){
		var thisColor = getAggregatedColor(
			arguments.testData.totalError,
			arguments.testData.totalFail,
			0
		);

		var didPrint = false;
		for ( var thisBundle in arguments.testData.bundleStats ) {
			if ( ( thisBundle.totalFail + thisBundle.totalError ) == 0 && !arguments.verbose ) {
				continue;
			}

			var thisColor = getAggregatedColor(
				thisBundle.totalError,
				thisBundle.totalFail,
				thisBundle.totalSkipped
			);
			var thisStatus = "pass";
			if ( thisBundle.totalFail > 0 || thisBundle.totalError > 0 ) {
				thisStatus = "error";
			}
			if ( thisBundle.totalSkipped == thisBundle.totalSpecs ) {
				thisStatus = "skipped";
			}

			arguments.print
				.line()
				.line(
					"#getIndicator( thisStatus )##thisBundle.name# (#thisBundle.totalDuration# ms)",
					thisColor
				)
				.line(
					"[Passed: #thisBundle.totalPass#] [Failed: #thisBundle.totalFail#] [Errors: #thisBundle.totalError#] [Skipped: #thisBundle.totalSkipped#] [Suites/Specs: #thisBundle.totalSuites#/#thisBundle.totalSpecs#]",
					thisColor
				)
				.line()

			// Check if the bundle threw a global exception
			if ( !isSimpleValue( thisBundle.globalException ) ) {
				arguments.print
					.line(
						"GLOBAL BUNDLE EXCEPTION",
						COLOR.ERROR
					)
					.line(
						"-> #thisBundle.globalException.type ?: "none"#:#thisBundle.globalException.message ?: "none"#:#thisBundle.globalException.detail ?: "none"#",
						COLOR.ERROR
					);

				var errorStack = [];

				// If there's a tag context, show the file name and line number where the error occurred
				if (
					isDefined( "thisBundle.globalException.tagContext" ) && isArray(
						thisBundle.globalException.tagContext
					) && thisBundle.globalException.tagContext.len()
				) {
					errorStack = thisBundle.globalException.tagContext;
				}

				// Show at least 5 stack origins, 1 is not enough for debugging.
				errorStack.each( function( item, index ){
					if ( index <= variables.MAX_STACKTRACES ) {
						print.line(
							"-> at #item.template#:#item.line# #chr( 13 )##chr( 13 )#",
							COLOR.ERROR
						);

						// code print for first stack frame if supported by the CFML engine
						if ( index == 1 && item.keyExists( "codePrintPlain" ) ) {
							print.line().line( item.codePrintPlain );
						}
					}
				} );

				// ACF has an array for the stack trace
				if ( isSimpleValue( thisBundle.globalException.stacktrace ) && !errorStack.len() ) {
					arguments.print
						.line(
							"---------------------------------------------------------------------------------",
							COLOR.ERROR
						)
						.line( "STACKTRACE", COLOR.ERROR )
						.line(
							"---------------------------------------------------------------------------------",
							COLOR.ERROR
						)
						.line(
							"#thisBundle.globalException.stacktrace#",
							COLOR.ERROR
						)
						.line(
							"---------------------------------------------------------------------------------",
							COLOR.ERROR
						)
						.line( "END STACKTRACE", COLOR.ERROR );
				}

				arguments.print.line(
					"---------------------------------------------------------------------------------",
					COLOR.ERROR
				);
			}

			// Generate reports for each suite
			for ( var suiteStats in thisBundle.suiteStats ) {
				didPrint = genSuiteReport(
					suiteStats  = suiteStats,
					bundleStats = thisBundle,
					level       = 1,
					print       = arguments.print,
					verbose     = arguments.verbose
				);
			}
		}

		var thisColor = getAggregatedColor(
			arguments.testData.totalError,
			arguments.testData.totalFail,
			0
		);

		// Print Summary
		// cfformat-ignore-start
		arguments.print
			.line()
			.line( "╔═════════════════════════════════════════════════════════════════════╗", thisColor )
			.line( "║ Passed  ║ Failed  ║ Errored ║ Skipped ║ Bundles ║ Suites  ║ Specs   ║", thisColor )
			.line( "╠═════════════════════════════════════════════════════════════════════╣", thisColor )
			.line(
				"║ #headerCell( arguments.testData.totalPass )# ║ #headerCell( arguments.testData.totalFail )# ║ #headerCell( arguments.testData.totalError )# ║ #headerCell( arguments.testData.totalSkipped )# ║ #headerCell( arguments.testData.totalBundles )# ║ #headerCell( arguments.testData.totalSuites )# ║ #headerCell( arguments.testData.totalSpecs )# ║",
				thisColor
				)
			.line( "╚═════════════════════════════════════════════════════════════════════╝", thisColor )
			.line()
			.line( "TestBox 	" & ( !isNull( arguments.testData.version ) ? "v#arguments.testData.version#" : "" ) )
			.line( "CFML Engine	" & ( !isNull( arguments.testData.cfmlEngine ) ? "#arguments.testData.cfmlEngine# v#arguments.testData.cfmlEngineVersion#" : "" ) )
			.line( "Duration 	#numberFormat( arguments.testData.totalDuration )#ms" )
			.line( "Labels 		" & ( arrayLen( arguments.testData.labels ) ? arrayToList( arguments.testData.labels ) : "---" ) );
		// cfformat-ignore-end

		if ( isDefined( "arguments.testData.coverage.enabled" ) && arguments.testData.coverage.enabled ) {
			arguments.print
				.line(
					"Coverage 	#arguments.testData.coverage.data.stats.totalCoveredLines# / #arguments.testData.coverage.data.stats.totalExecutableLines# LOC (#numberFormat(
						arguments.testData.coverage.data.stats.percTotalCoverage * 100,
						"9.9"
					)#%) Covered"
				)
				.line();
			if ( len( arguments.testData.coverage.data.sonarQubeResults ) ) {
				arguments.print.blueLine(
					"Coverage: SonarQube file written to [#arguments.testData.coverage.data.sonarQubeResults#]"
				);
			}
			if ( len( arguments.testData.coverage.data.browserResults ) ) {
				arguments.print.blueLine(
					"Coverage: Browser written to [#arguments.testData.coverage.data.browserResults#]"
				);
			}
		}

		// Skip this redundant line if no specs printed above in the previous suite
		if ( didPrint ) {
			arguments.print.line();
		}

		// If verbose print the final footer report
		if ( arguments.verbose ) {
			arguments.print
				.text(
					"#getIndicator( "passed" )#Passed",
					COLOR.PASS
				)
				.text( "  " )
				.text(
					"#getIndicator( "skipped" )#Skipped",
					COLOR.SKIP
				)
				.text( "  " )
				.text(
					"#getIndicator( "error" )#Exception/Error",
					COLOR.ERROR
				)
				.text( "  " )
				.text(
					"#getIndicator( "failed" )#Failure",
					COLOR.FAIL
				)
				.line()
		}
	}

	/**
	 * Get the indicator status
	 *
	 * @status The status to get back
	 */
	function getIndicator( required status ){
		if ( arguments.status == "error" ) {
			return "!! ";
		} else if ( arguments.status == "failed" ) {
			return "X ";
		} else if ( arguments.status == "skipped" ) {
			return "- ";
		} else {
			return "√ ";
		}
	}

	/**
	 * Recursive Output for suites
	 * @suiteStats Suite stats
	 * @bundleStats Bundle stats
	 * @level Generation level
	 * @print The print Buffer
	 * @verbose The verbose indicator
	 */
	function genSuiteReport(
		required suiteStats,
		required bundleStats,
		level = "0",
		required print,
		required verbose
	){
		// Return if not in verbose mode nd no errors
		if ( ( arguments.suiteStats.totalFail + arguments.suiteStats.totalError ) == 0 && !arguments.verbose ) {
			return false;
		}

		var tabs = repeatString( "    ", arguments.level );

		print.line(
			"#tabs##getIndicator( arguments.suiteStats.status )##arguments.suiteStats.name# #chr( 13 )#",
			getAggregatedColor(
				arguments.suiteStats.totalError,
				arguments.suiteStats.totalFail,
				( arguments.suiteStats.status == "skipped" ? 1 : 0 )
			)
		);

		var printedAtLeastOneLine = false;
		for ( local.thisSpec in arguments.suiteStats.specStats ) {
			// Continue if no exception and not in verbose mode
			if (
				listFindNoCase(
					"failed,exception,error",
					local.thisSpec.status
				) == 0 && !arguments.verbose
			) {
				continue;
			}

			printedAtLeastOneLine = true;
			var thisColor         = getAggregatedColor(
				( local.thisSpec.status == "error" ? 1 : 0 ),
				( local.thisSpec.status == "failed" ? 1 : 0 ),
				( local.thisSpec.status == "skipped" ? 1 : 0 )
			);

			print.line(
				"#repeatString( "    ", arguments.level + 1 )##getIndicator( local.thisSpec.status )##local.thisSpec.name# (#local.thisSpec.totalDuration# ms) #chr( 13 )#",
				thisColor
			);

			if ( local.thisSpec.status == "failed" ) {
				print.line(
					"#repeatString( "    ", arguments.level + 2 )#-> Failure: #local.thisSpec.failMessage##chr( 13 )#",
					COLOR.FAIL
				);

				param local.thisSpec.debugBuffer = [];
				if ( verbose && !local.thisSpec.debugBuffer.isEmpty() ) {
					print.text( repeatString( "    ", level + 2 ) ).boldWhiteOnGreenLine( "Debug Buffer:" );
					print
						.line(
							JSONPrettyPrint
								.formatJSON(
									json       = local.thisSpec.debugBuffer,
									ansiColors = JSONService.getANSIColors()
								)
								.listToArray( chr( 10 ) )
								.map( ( line ) => "#repeatString( "    ", level + 2 )##line#" )
								.toList( chr( 10 ) )
						)
						.line();
				}
			}

			if ( local.thisSpec.status == "error" ) {
				print.line(
					"#repeatString( "    ", arguments.level + 2 )#-> Error: #local.thisSpec.error.message##chr( 13 )#",
					COLOR.ERROR
				);

				var errorStack = [];

				// If there's a tag context, show the file name and line number where the error occurred
				if (
					isDefined( "local.thisSpec.error.tagContext" ) && isArray( local.thisSpec.error.tagContext ) && local.thisSpec.error.tagContext.len()
				) {
					errorStack = thisSpec.error.tagContext;
					// For some reason, the tag context sometimes is here.  Isn't consistency great??
				} else if (
					isDefined( "local.thisSpec.failOrigin" ) && isArray( local.thisSpec.failOrigin ) && local.thisSpec.failOrigin.len()
				) {
					errorStack = thisSpec.failOrigin;
				}

				// Show at least 5 stack origins, 1 is not enough for debugging.
				errorStack.each( function( item, index ){
					if ( index <= variables.MAX_STACKTRACES ) {
						print.line(
							"#repeatString( "    ", level + 2 )#-> at #item.template#:#item.line# #chr( 13 )##chr( 13 )#",
							COLOR.ERROR
						);

						// code print for first stack frame if supported by the CFML engine
						if ( index == 1 && item.keyExists( "codePrintPlain" ) ) {
							print
								.line()
								.line(
									"#repeatString( "    ", level + 2 )##item.codePrintPlain.replace(
										chr( 10 ),
										chr( 10 ) & repeatString( "    ", level + 2 ),
										"all"
									)#"
								);
						}
					}
				} );

				param local.thisSpec.debugBuffer = [];
				if ( verbose && !local.thisSpec.debugBuffer.isEmpty() ) {
					print.text( repeatString( "    ", level + 2 ) ).boldWhiteOnGreenLine( "Debug Buffer:" );
					print
						.line(
							JSONPrettyPrint
								.formatJSON(
									json       = local.thisSpec.debugBuffer,
									ansiColors = JSONService.getANSIColors()
								)
								.listToArray( chr( 10 ) )
								.map( ( line ) => "#repeatString( "    ", level + 2 )##line#" )
								.toList( chr( 10 ) )
						)
						.line();
				}
			}
		}

		// Nested Suites?
		if ( arrayLen( arguments.suiteStats.suiteStats ) ) {
			for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
				var didPrint = genSuiteReport(
					local.nestedSuite,
					arguments.bundleStats,
					arguments.level + 1,
					arguments.print,
					arguments.verbose
				)
				printedAtLeastOneLine = printedAtLeastOneLine || didPrint;
			}
		}

		return printedAtLeastOneLine;
	}

	/**
	 * Create a header cell
	 * @text The header text
	 */
	private function headerCell( required text ){
		return left(
			arguments.text & repeatString( " ", HEADER_CELL_CHARS ),
			HEADER_CELL_CHARS
		);
	}

	/**
	 * Get aggregate color for display
	 * @errors number of errors
	 * @failures number of failures
	 * @skips number of skipped specs
	 */
	private function getAggregatedColor( errors = 0, failures = 0, skips = 0 ){
		if ( errors ) {
			return COLOR.ERROR;
		} else if ( failures ) {
			return COLOR.FAIL;
		} else if ( skips ) {
			return COLOR.SKIP;
		} else {
			return COLOR.PASS;
		}
	}

}
