/**
 * Create a new TestBox test visualizer for an application. The test harness will be created in a directory called tests/test-visualizer.
 * .
 * You can run it from the root of your application.
 * {code:bash}
 * testbox create visualizer
 * {code}
 * .
 * Or pass the base directory of your application as a parameter
 * {code:bash}
 * testbox create visualizer C:\myApp
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * @directory The base directory to create your test visualizer
	 */
	function run( string directory = getCWD() ){
		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory & "/tests/test-visualizer" );

		// Make sure we have the latest TestBox for assets
		ensureTestBox( false );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );

			// Copy template
			directoryCopy(
				expandPath( "/testbox/test-visualizer" ),
				arguments.directory,
				true
			);

			// Print the results to the console
			print.greenLine( "Created " & arguments.directory );
		} else {
			error( "Directory #arguments.directory# already exists!" );
		}
	}

}
