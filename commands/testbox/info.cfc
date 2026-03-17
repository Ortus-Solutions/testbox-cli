/**
 * Display information about the TestBox installation being used by the CLI
 * and the current project. Shows the version, path on disk, and the source
 * (Local Project copy vs. CLI-bundled copy).
 * .
 * {code:bash}
 * testbox info
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * Show TestBox installation info
	 */
	function run(){
		var modulePath    = variables.moduleConfig.path;
		var bundlePath    = modulePath & "/testbox";
		var serverDetails = variables.serverService.resolveServerDetails( {} );
		var serverInfo    = serverDetails.serverInfo;

		// Determine the local-project TestBox path (same logic as ensureTestBox)
		var localTestBoxPath = resolvePath( "testbox", serverInfo.webroot );
		var localExists      = directoryExists( localTestBoxPath );
		var bundleExists     = directoryExists( bundlePath );

		// ── Not found anywhere ──────────────────────────────────────────────
		if ( !localExists && !bundleExists ) {
			showTestBoxBanner( "Installation Info" );
			printWarn( "TestBox could not be found in the project directory or in the CLI bundle path." );
			variables.print
				.yellowLine( "  Project path : #localTestBoxPath#" )
				.yellowLine( "  CLI path     : #bundlePath#" )
				.line()
				.toConsole();

			if ( confirm( "Would you like to install TestBox into the CLI bundle path now? [y/N]" ) ) {
				variables.print
					.line()
					.toConsole();
				command( "install" ).params( "testbox", modulePath ).run();
				// Re-check after install
				if ( directoryExists( bundlePath ) ) {
					variables.print.line().toConsole();
					printSuccess( "TestBox installed successfully!" );
					_printInstallInfo( bundlePath, "CLI Bundle" );
				}
			} else {
				printTip( "Run `testbox info` again after installing TestBox." );
			}
			return;
		}

		// ── Resolve active path (local project wins) ────────────────────────
		if ( localExists ) {
			var activePath   = localTestBoxPath;
			var activeSource = "Local Project";
		} else {
			var activePath   = bundlePath;
			var activeSource = "CLI Bundle";
		}

		// Create the /testbox mapping so expandPath works
		variables.fileSystemUtil.createMapping( "/testbox", activePath );

		// ── Banner + Info ────────────────────────────────────────────────────
		showTestBoxBanner( "Installation Info" );
		_printInstallInfo( activePath, activeSource );

		// If both sources exist, mention the secondary one
		if ( localExists && bundleExists ) {
			variables.print
				.line()
				.toConsole();
			printInfo( "A CLI-bundled copy also exists at: #bundlePath# (v#getTestBoxVersion( bundlePath )#)" );
		}
	}

	// ── Private ──────────────────────────────────────────────────────────────

	private function _printInstallInfo( required string testBoxPath, required string source ){
		var version = getTestBoxVersion( arguments.testBoxPath );
		var sep     = repeatString( "─", 55 );

		variables.print
			.line( "  #sep#", "color245" )
			.line()
			.boldWhite( "   Source  " ).line( " #arguments.source#" )
			.boldWhite( "   Version " ).line( " #version#" )
			.boldWhite( "   Path    " ).line( " #arguments.testBoxPath#" )
			.boldWhite( "   Mapping " ).line( " /testbox → #expandPath( "/testbox" )#" )
			.line()
			.line( "  #sep#", "color245" )
			.line()
			.toConsole();
	}

}
