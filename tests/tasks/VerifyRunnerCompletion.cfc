/** Run with CommandBox: box task run taskFile=tests/tasks/VerifyRunnerCompletion */
component {

	function run(){
		var root = variables.fileSystemUtil.resolvePath( "." )
		variables.fileSystemUtil.createMapping( "/runnerCompletionCLI", root )
		variables.fileSystemUtil.createMapping(
			"/testbox",
			expandPath( "/testboxCLI" ) & "/testbox"
		)
		var command = createObject(
			"component",
			"runnerCompletionCLI.commands.testbox.run"
		)
		// Exercise the real command's completion entry point without loading another CLI module.
		var mockbox = new testbox.system.MockBox()
		mockbox.prepareMock( command )
		command.$( "getCWD", root )
		var service = mockbox.createStub()
		command.$property(
			"packageService",
			"variables",
			service
		)
		for (
			var example in [
				{
					"runner"   : "/tests/runner.bxm",
					"expected" : [ "/tests/runner.bxm" ]
				},
				{
					"runner" : [
						{ "serial" : "/tests/runner.bxm" },
						{
							"parallel" : "/tests/runner.parallel.bxm",
							"unit"     : "/tests/unit.bxm"
						}
					],
					"expected" : [ "serial", "parallel", "unit" ]
				},
				{ "runner" : "", "expected" : [] },
				{ "runner" : [], "expected" : [] }
			]
		) {
			service.$(
				"readPackageDescriptor",
				{ "testbox" : { "runner" : example.runner } }
			)
			var actual = command.runnerComplete()
			actual.sort( "text" )
			example.expected.sort( "text" )
			if ( serializeJSON( actual ) != serializeJSON( example.expected ) ) {
				throw( message = "Runner completion did not match its configured names." )
			}
		}
		service.$( "readPackageDescriptor", {} )
		if ( command.runnerComplete().len() ) {
			throw( message = "Missing runner configuration should complete nothing." )
		}
		variables.print.greenLine( "Runner completion: 5 configuration cases passed." ).toConsole()
	}

}
