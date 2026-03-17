/**
 *********************************************************************************
 * Copyright Since 2014 CommandBox by Ortus Solutions, Corp
 * www.testbox.run | www.boxlang.io | www.ortussolutions.com
 ********************************************************************************
 * This class is the base command for all TestBox related commands. It provides shared utilities for
 * ensuring TestBox is available, discovering the runner URL, and other common tasks.
 */
component {

	// Global Injections
	property name="settings"       inject="box:modulesettings:testbox-cli";
	property name="moduleConfig"   inject="box:moduleConfig:testbox-cli";
	property name="serverService"  inject="serverService";
	property name="packageService" inject="PackageService";

	// These are the locations of the various TestBox resources that we will use for generation and running.
	// We will create mappings to these in the file system service when we ensure TestBox is installed.
	static{
		BROWSER_BX_PATH = "/testbox/bx/browser";
		BROWSER_CFML_PATH = "/testbox/cfml/browser";
		HARNESS_BX_PATH = "/testbox/bx/tests";
		HARNESS_CFML_PATH = "/testbox/cfml/tests";
		VISUALIZER_PATH = "/testbox/test-visualizer";
	}

	/**
	 * Ensure that TestBox is installed
	 *
	 * @testboxUseLocal Use a local version of TestBox or in the execution path. Defaults to true, else it tries to download it
	 *
	 * @return string The path to TestBox
	 */
	string function ensureTestBox( boolean testboxUseLocal = true ){
		// Where it should go in the module installed locally
		var testBoxPath   = variables.moduleConfig.path & "/testbox";
		var modulePath    = variables.moduleConfig.path;
		var serverDetails = variables.serverService.resolveServerDetails( {} );
		var serverInfo    = serverDetails.serverInfo;

		// If using local, check if we have a local version first
		if ( arguments.testboxUseLocal ) {
			// Check if we have a local version
			var localTestBoxPath = resolvePath( "testbox", serverInfo.webroot );
			if ( directoryExists( localTestBoxPath ) ) {
				testBoxPath = localTestBoxPath;
			}
		}

		// If we don't have one by here, then download it
		if ( !directoryExists( testBoxPath ) ) {
			variables.print
				.blackOnWheat1( " WARN  " )
				.line( " Uh-oh, TestBox could not be found locally [#testBoxPath#] or in the CLI path." )
				.green1onDodgerBlue2( " INFO  " )
				.line( " We will install a local version in the CLI path [#modulePath#] for you." )
				.line()
				.toConsole();

			command( "install" ).params( "testbox", modulePath ).run();
			testBoxPath = modulePath & "/testbox"
		}

		// Add our mapping
		variables.fileSystemUtil.createMapping( "/testbox", testBoxPath );
		// variables.print
		// 	.green1onDodgerBlue2( " INFO  " )
		// 	.line( " Created [/testbox] mapping at [#testBoxPath#]" )
		// 	.toConsole();

		return testBoxPath;
	}

	/**
	 * Discover the testbox runner URL from
	 * 1) Passed argument
	 * 2) box.json descriptor
	 * 3) Current server descriptor
	 *
	 * @runner The runner argument
	 */
	string function discoverRunnerUrl( required string runner ){
		// If a URL is passed, used it as an override
		if ( left( arguments.runner, 4 ) == "http" || left( arguments.runner, 1 ) == "/" ) {
			if ( !find( "?", arguments.runner ) ) {
				arguments.runner &= "?";
			}
			return arguments.runner;
		}

		// Get Runner from the box.json
		var runnerUrl = variables.testingService.getTestBoxRunner( getCWD(), arguments.runner );

		// Validate runner
		if ( !len( runnerUrl ) ) {
			var boxJSON       = variables.packageService.readPackageDescriptor( getCWD() );
			var boxJSONRunner = boxJSON.testbox.runner ?: "";
			return error(
				"[#arguments.runner#] it not a valid runner in your box.json. Runners found are: #boxJSONRunner.toString()#"
			);
		}

		// Resolve relative URI, and match to the server defined in this package
		if ( left( runnerUrl, 1 ) == "/" ) {
			var serverDetails = variables.serverService.resolveServerDetails( {} );
			var serverInfo    = serverDetails.serverInfo;

			if ( serverDetails.serverIsNew ) {
				error(
					"The test runner we found [#runnerUrl#] looks like partial URI, but we can't find any servers in this directory. Please give us a full URL."
				);
			} else {
				runnerUrl = ( serverInfo.SSLEnable ? "https://" : "http://" ) & "#serverInfo.host#:#serverInfo.port##runnerUrl#";
			}
		}

		// If we failed to find a URL, throw an error
		if ( left( runnerUrl, 4 ) != "http" ) {
			return error( "[#runnerUrl#] it not a valid URL, or does not match a runner slug in your box.json." );
		}

		if ( !find( "?", runnerUrl ) ) {
			runnerUrl &= "?";
		}

		return runnerUrl;
	}

	/**
	 * Get the testbox descriptor from the package descriptor
	 *
	 * @cwd The current working directory
	 */
 	function getTestBoxDescriptor( required cwd=getCwd() ){
		return variables.packageService.readPackageDescriptor( arguments.cwd ).testbox;
	}

	/**
	 * Determines if we are running on a BoxLang server
	 * or using the BoxLang runner.
	 *
	 * @cwd The current working directory
	 *
	 * @return boolean
	 */
	function isBoxLangProject( required cwd ){
		// Detect if it's a BoxLang server first.
		var serverInfo = variables.serverService.resolveServerDetails( {} ).serverInfo;
		if ( serverInfo.cfengine.findNoCase( "boxlang" ) ) {
			return true;
		}

		// Detect if you have the BoxLang runner set.
		var boxOptions = variables.packageService.readPackageDescriptor( arguments.cwd );
		if (
			boxOptions.testbox.keyExists( "runner" )
			&& isSimpleValue( boxOptions.testbox.runner )
			&& boxOptions.testbox.runner == "boxlang"
		) {
			return true;
		}

		// Language mode
		if ( boxOptions.keyExists( "language" ) && boxOptions.language == "boxlang" ) {
			return true;
		}

		// We don't know.
		return false;
	}

	/**
	 * Convert a component definition to a BoxLang class definition by replacing the "component" keyword with "class"
	 *
	 * @content The content of the component to convert
	 *
	 * @return string The converted class definition
	 */
	function toBoxLangClass( required content ){
		return reReplaceNoCase(
			arguments.content,
			"component(\s|\n)?",
			"class #chr( 13 )#",
			"one"
		);
	}

	// -------------------------------------------------------------------------
	// Print Helpers
	// -------------------------------------------------------------------------

	function printInfo( required message ){
		variables.print
			.green1onDodgerBlue2( " INFO  " )
			.line( " #arguments.message#" )
			.line()
	}

	function printError( required message ){
		variables.print
			.whiteOnRed2( " ERROR " )
			.line( " #arguments.message#" )
			.line()
	}

	function printWarn( required message ){
		variables.print
			.blackOnWheat1( " WARN  " )
			.line( " #arguments.message#" )
			.line()
	}

	function printSuccess( required message ){
		variables.print
			.blackOnSeaGreen2( " SUCCESS  " )
			.line( " #arguments.message#" )
			.line()
	}

	function printTip( required string message ){
		variables.print
			.blackOnAquamarine2( "  TIP  " )
			.line( " #arguments.message#" )
			.line()
	}

	function printHelp( required message ){
		variables.print
			.blackOnLightSkyBlue1( " HELP  " )
			.line( " #arguments.message#" )
			.line()
	}

	/**
	 * Read the version string from a TestBox installation's box.json.
	 *
	 * @testBoxPath Absolute path to the TestBox installation directory
	 *
	 * @return string Version string, or "unknown" if not determinable
	 */
	string function getTestBoxVersion( required string testBoxPath ){
		var boxJsonPath = arguments.testBoxPath & "/box.json";
		if ( !fileExists( boxJsonPath ) ) {
			return "unknown";
		}
		try {
			var descriptor = deserializeJSON( fileRead( boxJsonPath ) );
			return descriptor.version ?: "unknown";
		} catch ( any e ) {
			return "unknown";
		}
	}

	/**
	 * Display the TestBox ASCII art banner with random gradient colors.
	 *
	 * @subTitle Optional subtitle to display below the banner
	 * @theme    Optional gradient theme name (e.g., "Ocean", "Fire", "Sunset", "Purple", "Mint", "Gray")
	 */
	function showTestBoxBanner(
		string subTitle = "",
		string theme    = ""
	){
		var lines = [
			" ████████╗███████╗███████╗████████╗ ██████╗  ██████╗ ██╗  ██╗",
			"    ██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔══██╗ ██╔══██╗╚██╗██╔╝",
			"    ██║   █████╗  ███████╗   ██║   ██████╔╝ ██║  ██║ ╚███╔╝ ",
			"    ██║   ██╔══╝  ╚════██║   ██║   ██╔══██╗ ██║  ██║ ██╔██╗ ",
			"    ██║   ███████╗███████║   ██║   ██████╔╝ ██████╔╝██╔╝ ██╗",
			"    ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝"
		]

		var themes = {
			"Ocean" : [
				"color81",
				"color75",
				"color69",
				"color63",
				"color57",
				"color21"
			],
			"Fire" : [
				"color196",
				"color202",
				"color208",
				"color214",
				"color220",
				"color226"
			],
			"Sunset" : [
				"color214",
				"color208",
				"color202",
				"color196",
				"color160",
				"color124"
			],
			"Purple" : [
				"color213",
				"color177",
				"color141",
				"color105",
				"color69",
				"color39"
			],
			"Mint" : [
				"color158",
				"color122",
				"color86",
				"color50",
				"color44",
				"color38"
			],
			"Gray" : [
				"color250",
				"color248",
				"color245",
				"color243",
				"color240",
				"color238"
			],
			"Forest" : [
				"color154",
				"color148",
				"color142",
				"color106",
				"color70",
				"color34"
			],
			"Gold" : [
				"color226",
				"color220",
				"color214",
				"color208",
				"color172",
				"color136"
			]
		}

		// Randomly select a gradient theme if none provided
		if ( arguments.theme == "" ) {
			var themeNames = structKeyArray( themes )
			var themeName  = themeNames[ randRange( 1, arrayLen( themeNames ) ) ]
		} else {
			var themeName = arguments.theme
		}
		var gradient = themes[ themeName ]

		variables.print.line()

		for ( var i = 1; i <= arrayLen( lines ); i++ ) {
			variables.print.line( lines[ i ], gradient[ i ] )
		}

		// Add subtitle block if provided
		if ( len( arguments.subTitle ) ) {
			var blockWidth   = 48
			var contentWidth = blockWidth - 4
			var padding      = contentWidth - len( arguments.subTitle )
			var leftPad      = int( padding / 2 )
			var rightPad     = padding - leftPad
			var indent       = repeatString( " ", 3 )

			variables.print
				.line(
					indent & repeatString( "▄", blockWidth ),
					gradient.last()
				)
				.line(
					indent & "██" &
					repeatString( " ", leftPad ) &
					arguments.subTitle &
					repeatString( " ", rightPad ) &
					"██",
					"white"
				)
				.line(
					indent & repeatString( "▀", blockWidth ),
					gradient.last()
				)
		}

		variables.print.line()
	}

}
