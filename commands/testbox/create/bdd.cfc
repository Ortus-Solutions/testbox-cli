/**
 * Create a new BDD spec in an existing application.  By default, your new BDD spec will be created in the current working
 * directory but you can override that with the directory param.
 * .
 * {code:bash}
 * testbox create bdd mySpec
 * {code}
 *
 **/
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * @name Name of the BDD spec to create without the .cfc. For packages, specify name as 'myPackage/myBDDSpec'
	 * @open Open the file once it is created
	 * @directory The base directory to create your BDD spec in and creates the directory if it does not exist.
	 * @boxlang   Is this a boxlang project? else it is a CFML project
	 **/
	function run(
		required name,
		boolean open    = false,
		directory       = getCWD(),
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		isBoxLangProject();
		return;

		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, ".", "/", "all" );

		// Check if the name is actually a path
		var nameArray       = arguments.name.listToArray( "/" );
		var nameArrayLength = nameArray.len();
		if ( nameArrayLength > 1 ) {
			// If it is a path, split the path from the name
			arguments.name   = nameArray[ nameArrayLength ];
			var extendedPath = nameArray.slice( 1, nameArrayLength - 1 ).toList( "/" );
			arguments.directory &= "/#extendedPath#";
		}

		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// This help readability so the success messages aren't up against the previous command line
		print.line();

		// Read in Templates
		var BDDContent = fileRead( "#variables.settings.templatesPath#/#arguments.boxlang ? "bx" : "cfml"#/bdd.txt" );

		// Write out BDD Spec
		var BDDPath= "#arguments.directory#/#name#.cfc";
		file action="write" file="#BDDPath#" mode="777" output="#BDDContent#";
		print.greenLine( "Created #BDDPath#" );

		// Open file?
		if ( arguments.open ) {
			openPath( bddPath );
		}
	}

}
