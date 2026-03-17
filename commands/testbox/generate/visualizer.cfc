/**
 * Generate a new TestBox test visualizer for an application. The test visualizer will be created in a directory called tests/test-visualizer.
 * .
 * You can run it from the root of your application.
 * {code:bash}
 * testbox generate visualizer
 * {code}
 * .
 * Or pass the base directory of your application as a parameter
 * {code:bash}
 * testbox generate visualizer C:\myApp
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * @directory The base directory to create your test visualizer
	 */
	function run( string directory = getCWD() ){
		showTestBoxBanner( "generate visualizer" );

		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory & "/tests/test-visualizer" );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );

			// Ensure TestBox is installed
			ensureTestBox()

			// Copy template from testbox source
			directoryCopy(
				expandPath( static.VISUALIZER_PATH ),
				arguments.directory,
				true
			);

			// Print the results to the console
			printSuccess( "Generated visualizer at: #arguments.directory#" );
		} else {
			error( "Directory [#arguments.directory#] already exists!" );
		}
	}

}
