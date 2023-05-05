component excludeFromHelp=true {

	property name="config" inject="box:moduleconfig:testbox-cli";

	function run(){
		variables.print
			.line()
			.blue( "The " )
			.boldGreen( "testbox" )
			.blueLine( " namespace helps you do anything related to your TestBox installation. Use these commands" )
			.blueLine( "to create tests, generate runners, and even run your tests for you from the command line." )
			.blueLine(
				"Type help before any command name to get additional information on how to call that specific command."
			)
			.line()
			.line()
			.greenLine( "TestBox CLI Version: #config.version#" )
			.line();
	}

}
