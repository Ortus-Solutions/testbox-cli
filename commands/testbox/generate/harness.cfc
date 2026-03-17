/**
 * Generate a new TestBox test harness for an application. The test harness will be created in a directory called tests.
 * .
 * You can run it from the root of your application.
 * {code:bash}
 * testbox generate harness
 * {code}
 * .
 * Or pass the base directory of your application as a parameter
 * {code:bash}
 * testbox generate harness C:\myApp
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * @directory The base directory to create your test harness
	 * @boxlang   Is this a boxlang project? else it is a CFML project
	 */
	function run(
		string directory = getCWD(),
		boolean boxlang  = isBoxLangProject( getCWD() )
	){
		showTestBoxBanner( "generate harness" );

		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory & "/tests" );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );

			// Ensure TestBox is installed
			ensureTestBox()

			var sourcePath = arguments.boxlang ? static.HARNESS_BX_PATH : static.HARNESS_CFML_PATH;
			// Copy template from testbox source
			directoryCopy(
				expandPath( sourcePath ),
				arguments.directory,
				true
			);

			// Print the results to the console
			printSuccess( "Generated harness at: #arguments.directory#" );
		} else {
			error( "Directory [#arguments.directory#] already exists!" );
		}
	}

}
