/**
 * Generate a new TestBox test browser for an application. The test browser will be created in a directory called tests/test-browser.
 * .
 * You can run it from the root of your application.
 * {code:bash}
 * testbox generate browser
 * {code}
 * .
 * Or pass the base directory of your application as a parameter
 * {code:bash}
 * testbox generate browser C:\myApp
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * @directory The base directory to create your test browser
	 * @boxlang   Is this a boxlang project? else it is a CFML project
	 */
	function run(
		string directory = getCWD(),
		boolean boxlang  = isBoxLangProject( getCWD() )
	){
		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory & "/tests/browser" )

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory )

			// Ensure TestBox is installed
			ensureTestBox()

			// Copy template from testbox source
			var sourcePath = arguments.boxlang ? static.BROWSER_BX_PATH : static.BROWSER_CFML_PATH;
			directoryCopy(
				expandPath( sourcePath ),
				arguments.directory,
				true
			)

			// Print the results to the console
			print.greenLine( "Generated browser at [#arguments.directory#]" )
		} else {
			error( "Directory [#arguments.directory#] already exists!" )
		}
	}

}
