/**
 * Wipe and reinstall the CLI-bundled copy of TestBox.
 * .
 * This command only operates on the TestBox copy that is bundled inside
 * the testbox-cli CLI module itself. It does NOT touch any TestBox
 * installation inside your project — that is your responsibility.
 * .
 * {code:bash}
 * testbox reinstall
 * {code}
 * .
 * Install a specific version:
 * {code:bash}
 * testbox reinstall version=5.3.0
 * {code}
 * .
 * Skip the confirmation prompt with --force:
 * {code:bash}
 * testbox reinstall --force
 * testbox reinstall version=5.3.0 --force
 * {code}
 */
component extends="testboxCLI.models.BaseCommand" {

	/**
	 * Wipe and reinstall the CLI-bundled TestBox
	 *
	 * @version The specific TestBox version to install (e.g., 5.3.0). Defaults to the latest stable release.
	 * @force   Skip the confirmation prompt and reinstall immediately
	 */
	function run(
		string version = "",
		boolean force  = false
	){
		var modulePath  = variables.moduleConfig.path;
		var bundlePath  = modulePath & "/testbox";
		var installSlug = len( arguments.version ) ? "testbox@#arguments.version#" : "testbox";

		showTestBoxBanner( "Reinstall CLI Bundle" );

		// ── Nothing there to wipe ────────────────────────────────────────────
		if ( !directoryExists( bundlePath ) ) {
			printWarn( "No CLI-bundled TestBox installation found at:" );
			variables.print
				.yellowLine( "  #bundlePath#" )
				.line()
				.toConsole();
			printTip( "Run `testbox info` to check what is currently installed." );
			return;
		}

		// ── Confirm unless --force ───────────────────────────────────────────
		var currentVersion = getTestBoxVersion( bundlePath );
		variables.print
			.line()
			.boldWhite( "   CLI Bundle Path    " )
			.line( " #bundlePath#" )
			.boldWhite( "   Installed Version  " )
			.line( " #currentVersion#" )
			.boldWhite( "   Target Version     " )
			.line( " #( len( arguments.version ) ? arguments.version : "latest stable" )#" )
			.line()
			.toConsole();

		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to wipe and reinstall the CLI-bundled TestBox? [y/N]" ) ) {
				printWarn( "Reinstall cancelled." );
				return;
			}
		}

		// ── Wipe ─────────────────────────────────────────────────────────────
		variables.print.line().toConsole();
		printInfo( "Removing CLI-bundled TestBox at: #bundlePath#" );
		variables.print.toConsole();
		directoryDelete( bundlePath, true );
		printSuccess( "CLI-bundled TestBox removed." );
		variables.print.toConsole();

		// ── Reinstall ─────────────────────────────────────────────────────────
		printInfo( "Installing #installSlug# into CLI path: #modulePath#" );
		variables.print.toConsole();
		command( "install" ).params( installSlug, modulePath ).run();

		// ── Result ────────────────────────────────────────────────────────────
		if ( directoryExists( bundlePath ) ) {
			var newVersion = getTestBoxVersion( bundlePath );
			variables.print.line().toConsole();
			printSuccess( "TestBox v#newVersion# reinstalled successfully into the CLI bundle path!" );
			variables.print
				.boldWhite( "   Path    " )
				.line( " #bundlePath#" )
				.line()
				.toConsole();
		} else {
			printError( "Something went wrong — TestBox directory not found after install. Try running `box install #installSlug# #modulePath#` manually." );
		}
	}

}
