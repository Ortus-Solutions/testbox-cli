component {

	// Global Injections
	property name="settings"       inject="box:modulesettings:testbox-cli";
	property name="moduleConfig"   inject="box:moduleConfig:testbox-cli";
	property name="serverService"  inject="serverService";
	property name="packageService" inject="PackageService";

	/**
	 * Ensure that TestBox is installed
	 *
	 * @testboxUseLocal Use a local version of TestBox or in the execution path. Defaults to true, else it tries to download it
	 */
	private function ensureTestBox( boolean testboxUseLocal = true ){
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
	}

	/**
	 * Discover the testbox runner URL from
	 * 1) Passed argument
	 * 2) box.json descriptor
	 * 3) Current server descriptor
	 *
	 * @runner The runner argument
	 */
	private function discoverRunnerUrl( runner ){
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
	private function getTestBoxDescriptor( required cwd ){
		return variables.packageService.readPackageDescriptor( getCWD() ).testbox;
	}

	/**
	 * Determines if we are running on a BoxLang server
	 * or using the BoxLang runner.
	 *
	 * @cwd The current working directory
	 *
	 * @return boolean
	 */
	private function isBoxLangProject( required cwd ){
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

}
