component excludeFromHelp=true extends="testboxCLI.models.BaseCommand" {

	property name="config" inject="box:moduleconfig:testbox-cli";

	function run(){
		showTestBoxBanner( "v#config.version#" );

		variables.print
			.boldWhiteLine( "  The testbox namespace is your one-stop shop for everything TestBox!" )
			.line()
			.line( "  🚀  Run your tests from the CLI or via HTTP" )
			.line( "  🧪  Create BDD specs and xUnit test bundles" )
			.line( "  🏗️   Generate test harnesses, browsers, visualizers and modules" )
			.line( "  👁️   Watch for file changes and re-run tests automatically" )
			.line( "  📦  Manage your CLI-bundled TestBox installation" )
			.line()
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.boldCyanLine( "  Commands" )
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.line()
			.boldWhite( "  testbox run" ).line( "              Run your test suites via HTTP" )
			.boldWhite( "  testbox watch" ).line( "            Watch files and auto-run tests on change" )
			.boldWhite( "  testbox info" ).line( "             Show the active TestBox version and path" )
			.boldWhite( "  testbox reinstall" ).line( "        Wipe and reinstall the CLI-bundled TestBox" )
			.boldWhite( "  testbox create" ).line( "           Create BDD specs or xUnit test bundles" )
			.boldWhite( "  testbox generate" ).line( "         Generate harnesses, browsers, and more" )
			.boldWhite( "  testbox docs" ).line( "             Open the TestBox documentation in a browser" )
			.boldWhite( "  testbox apidocs" ).line( "          Open the TestBox API docs in a browser" )
			.line()
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.boldCyanLine( "  Examples" )
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.line()
			.line( "  ## Run tests using the URL in your box.json" )
			.boldGreenLine( "  testbox run" )
			.line()
			.line( "  ## Run only a specific bundle" )
			.boldGreenLine( "  testbox run bundles=tests.specs.UserSpec" )
			.line()
			.line( "  ## Stream results live as tests execute" )
			.boldGreenLine( "  testbox run --streaming" )
			.line()
			.line( "  ## Watch for changes and re-run automatically" )
			.boldGreenLine( "  testbox watch" )
			.line()
			.line( "  ## Create a new BDD spec" )
			.boldGreenLine( "  testbox create bdd MyFeatureSpec" )
			.line()
			.line( "  ## Generate a full test harness in the current project" )
			.boldGreenLine( "  testbox generate harness" )
			.line()
			.line( "  💡  Type " )
			.boldWhite( "help testbox <command>" )
			.line( " for detailed usage on any command." )
			.line();
	}

}
