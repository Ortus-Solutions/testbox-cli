/** Combine JSON results from independent CI shards and verify the entire suite selection completed. */
component extends="testboxCLI.models.BaseCommand" {

	property name="CLIRenderer" inject="CLIRenderer@testbox-cli";

	/**
	 * @directory Directory containing downloaded shard JSON artifacts (searched recursively).
	 * @outputFile Combined JSON results to write.
	 * @testboxUseLocal Use the project's TestBox installation when available.
	 */
	function run(
		required string directory,
		string outputFile       = "",
		boolean testboxUseLocal = true
	){
		var source      = resolvePath( arguments.directory )
		var destination = len( arguments.outputFile ) ? resolvePath( arguments.outputFile ) : ""
		var testboxPath = ensureTestBox( arguments.testboxUseLocal )
		if ( !fileExists( testboxPath & "/system/parallel/ShardPlan.cfc" ) ) {
			return error( "Merging shard reports requires the TestBox version with CI sharding support." )
		}
		if ( !directoryExists( source ) ) {
			return error( "Shard report directory does not exist: " & source )
		}
		var reports = []
		var files   = directoryList( source, true, "path", "*.json" )
		files.sort( "text" )
		for ( var path in files ) {
			if ( len( destination ) && path == destination ) {
				continue;
			}
			reports.append( deserializeJSON( fileRead( path ) ) )
		}
		try {
			var result = new testbox.system.parallel.ShardPlan().merge( reports )
		} catch ( any mergeError ) {
			return error( "Cannot combine CI results: " & mergeError.message )
		}
		if ( len( destination ) ) {
			directoryCreate(
				getDirectoryFromPath( destination ),
				true,
				true
			)
			fileWrite( destination, serializeJSON( result ) )
		}
		variables.print
			.line( result.sharding.shards & " shards verified; every selected bundle was reported exactly once." )
			.toConsole()
		variables.print.line( "Elapsed below is the longest shard, not CI workflow wall time." ).toConsole()
		variables.CLIRenderer.render( variables.print, result, false )
		if ( !result.passed ) {
			setExitCode( 1 )
		}
	}

}
