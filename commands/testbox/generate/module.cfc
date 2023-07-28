/**
 * Create a new TestBox module according to your passed name
 * .
 * You can run it from the root of your application.
 * {code:bash}
 * testbox create module myModule
 * {code}
 *
 * You can also call it and create it in a specific directory
 *  * {code:bash}
 * testbox create module myModule tests/resources/modules
 * {code}
 */
component {

	property name="settings" inject="box:modulesettings:testbox-cli";

	/**
	 * @name The name of the module
	 * @rootDirectory Where to create the module, by default it will be in the same folder as you call the command
	 */
	function run(
		required name,
		string rootDirectory = getCWD()
	){
		var moduleDirectory = resolvePath( arguments.rootDirectory ) & "/" & arguments.name;

		// Validate directory
		if ( !directoryExists( moduleDirectory ) ) {
			directoryCreate( moduleDirectory );

			// Copy template
			directoryCopy(
				"#variables.settings.templatesPath#/testbox/module/",
				moduleDirectory,
				true
			);

			// Print the results to the console
			print.greenLine( "Created the module at [#moduleDirectory#]" );
		} else {
			error( "Directory #moduleDirectory# already exists!" );
		}
	}

}
