component excludeFromHelp=true extends="testboxCLI.models.BaseCommand" {

	function run(){
		showTestBoxBanner( "testbox create" );

		variables.print
			.boldWhiteLine( "  Quickly scaffold BDD specs and xUnit test bundles for your application." )
			.line()
			.line( "  🧪  BDD specs use describe/it blocks with fluent expectations" )
			.line( "  🔬  xUnit bundles use setup/tearDown lifecycle methods" )
			.line( "  📂  Files are created in the current working directory by default" )
			.line( "  🌐  Both BoxLang (.bx) and CFML (.cfc) are supported" )
			.line()
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.boldCyanLine( "  Commands" )
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.line()
			.boldWhite( "  testbox create bdd" ).line( "     <name>   Create a new BDD spec" )
			.boldWhite( "  testbox create unit" ).line( "    <name>   Create a new xUnit test bundle" )
			.boldWhite( "  testbox generate module" ).line( " <name>   Create a TestBox module skeleton" )
			.line()
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.boldCyanLine( "  Examples" )
			.boldCyanLine( "  ─────────────────────────────────────────────────────" )
			.line()
			.line( "  ## Create a BDD spec in the current directory" )
			.boldGreenLine( "  testbox create bdd UserSpec" )
			.line()
			.line( "  ## Create a spec in a sub-package" )
			.boldGreenLine( "  testbox create bdd myPackage/UserSpec" )
			.line()
			.line( "  ## Create a spec and open it immediately" )
			.boldGreenLine( "  testbox create bdd UserSpec --open" )
			.line()
			.line( "  ## Create a BDD spec as a BoxLang class (.bx)" )
			.boldGreenLine( "  testbox create bdd UserSpec --boxlang" )
			.line()
			.line( "  ## Create an xUnit test bundle" )
			.boldGreenLine( "  testbox create unit UserServiceTest" )
			.line()
			.line( "  ## Create a xUnit test in a specific directory" )
			.boldGreenLine( "  testbox create unit UserServiceTest directory=tests/unit" )
			.line()
			.line( "  💡  Type " )
			.boldWhite( "help testbox create <command>" )
			.line( " for detailed usage on any command." )
			.line();
	}

}
