/**
 * Tests for StreamingRenderer output behavior
 */
component extends="testbox.system.BaseSpec" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		variables.renderer = new models.StreamingRenderer();
		// ANSI codes for verification (must match StreamingRenderer.cfc)
		variables.ANSI = {
			"CLEAR_LINE"      : chr( 27 ) & "[2K",  // Clear entire line
			"CARRIAGE_RETURN" : chr( 13 )
		};
	}

	function afterAll(){
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "StreamingRenderer", () => {
			beforeEach( () => {
				// Reset renderer state before each test
				renderer.resetState();
				// Create a mock print buffer that captures output
				variables.mockPrint = createMockPrint();
			} );

			describe( "without verbose flag", () => {
				it( "should NOT show passing specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					// Simulate a passing spec
					handlers.specStart( { "name" : "should pass", "displayName" : "should pass" } );
					handlers.specEnd( {
						"name"          : "should pass",
						"displayName"   : "should pass",
						"status"        : "passed",
						"totalDuration" : 10
					} );

					// The output should only contain the clear line sequence, not the spec result
					var output = mockPrint.getOutput();
					// Should have the running indicator cleared
					expect( output ).toInclude( variables.ANSI.CARRIAGE_RETURN );
					expect( output ).toInclude( variables.ANSI.CLEAR_LINE );
					// Should NOT have the passed indicator
					expect( output ).notToInclude( "√" );
				} );

				it( "should show failed specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					// Simulate a failing spec
					handlers.specStart( { "name" : "should fail", "displayName" : "should fail" } );
					handlers.specEnd( {
						"name"          : "should fail",
						"displayName"   : "should fail",
						"status"        : "failed",
						"totalDuration" : 15,
						"failMessage"   : "Expected true but got false"
					} );

					var output = mockPrint.getOutput();
					// Should show the failed indicator and message
					expect( output ).toInclude( "X" );
					expect( output ).toInclude( "should fail" );
					expect( output ).toInclude( "Expected true but got false" );
				} );

				it( "should show error specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					// Simulate an error spec
					handlers.specStart( { "name" : "should error", "displayName" : "should error" } );
					handlers.specEnd( {
						"name"          : "should error",
						"displayName"   : "should error",
						"status"        : "error",
						"totalDuration" : 20,
						"error"         : { "message" : "NullPointerException" }
					} );

					var output = mockPrint.getOutput();
					// Should show the error indicator and message
					expect( output ).toInclude( "!!" );
					expect( output ).toInclude( "should error" );
					expect( output ).toInclude( "NullPointerException" );
				} );

				it( "should show skipped specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					// Simulate a skipped spec
					handlers.specStart( { "name" : "should be skipped", "displayName" : "should be skipped" } );
					handlers.specEnd( {
						"name"          : "should be skipped",
						"displayName"   : "should be skipped",
						"status"        : "skipped",
						"totalDuration" : 0
					} );

					var output = mockPrint.getOutput();
					// Should show the skipped indicator
					expect( output ).toInclude( "-" );
					expect( output ).toInclude( "should be skipped" );
				} );
			} );

			describe( "with verbose flag", () => {
				it( "should show passing specs when verbose is true", () => {
					var handlers = renderer.createEventHandlers( mockPrint, true );

					// Simulate a passing spec
					handlers.specStart( { "name" : "should pass", "displayName" : "should pass" } );
					handlers.specEnd( {
						"name"          : "should pass",
						"displayName"   : "should pass",
						"status"        : "passed",
						"totalDuration" : 10
					} );

					var output = mockPrint.getOutput();
					// Should show the passed indicator
					expect( output ).toInclude( "√" );
					expect( output ).toInclude( "should pass" );
				} );
			} );

			describe( "color configuration", () => {
				it( "should use gray color for skipped specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					// Simulate a skipped spec
					handlers.specStart( { "name" : "skipped test", "displayName" : "skipped test" } );
					handlers.specEnd( {
						"name"          : "skipped test",
						"displayName"   : "skipped test",
						"status"        : "skipped",
						"totalDuration" : 0
					} );

					// Check the color was set to gray
					var colors = mockPrint.getColors();
					expect( colors ).toInclude( "gray" );
				} );

				it( "should use red color for failed specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					handlers.specStart( { "name" : "failed test", "displayName" : "failed test" } );
					handlers.specEnd( {
						"name"          : "failed test",
						"displayName"   : "failed test",
						"status"        : "failed",
						"totalDuration" : 10,
						"failMessage"   : "Assertion failed"
					} );

					var colors = mockPrint.getColors();
					expect( colors ).toInclude( "red" );
				} );

				it( "should use boldRed color for error specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					handlers.specStart( { "name" : "error test", "displayName" : "error test" } );
					handlers.specEnd( {
						"name"          : "error test",
						"displayName"   : "error test",
						"status"        : "error",
						"totalDuration" : 10,
						"error"         : { "message" : "Runtime error" }
					} );

					var colors = mockPrint.getColors();
					expect( colors ).toInclude( "boldRed" );
				} );

				it( "should use yellow color for running specs", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					handlers.specStart( { "name" : "running test", "displayName" : "running test" } );

					var colors = mockPrint.getColors();
					expect( colors ).toInclude( "yellow" );
				} );
			} );

			describe( "running spec indicator", () => {
				it( "should show running indicator on specStart", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					handlers.specStart( { "name" : "my test", "displayName" : "my test" } );

					var output = mockPrint.getOutput();
					expect( output ).toInclude( "»" );
					expect( output ).toInclude( "my test" );
					expect( output ).toInclude( "..." );
				} );

				it( "should clear running line before showing result", () => {
					var handlers = renderer.createEventHandlers( mockPrint, false );

					handlers.specStart( { "name" : "failing test", "displayName" : "failing test" } );
					handlers.specEnd( {
						"name"          : "failing test",
						"displayName"   : "failing test",
						"status"        : "failed",
						"totalDuration" : 10,
						"failMessage"   : "Failed"
					} );

					var output = mockPrint.getOutput();
					// Should have clear line before the result
					var clearLinePos = find( variables.ANSI.CLEAR_LINE, output );
					var failedPos    = find( "X", output );
					expect( clearLinePos ).toBeGT( 0 );
					expect( failedPos ).toBeGT( clearLinePos );
				} );
			} );
		} );
	}

	/*********************************** HELPER METHODS ***********************************/

	/**
	 * Creates a mock print object that captures output for testing
	 */
	private function createMockPrint(){
		// Use local variables that closures can reference
		var outputBuffer = { "value" : "" };
		var colorsBuffer = { "value" : [] };

		var mock = {
			"_outputBuffer" : outputBuffer,
			"_colorsBuffer" : colorsBuffer,
			"text" : function( text, color = "" ){
				outputBuffer.value &= arguments.text;
				if ( len( arguments.color ) ) {
					colorsBuffer.value.append( arguments.color );
				}
				return mock;
			},
			"line" : function( text = "", color = "" ){
				outputBuffer.value &= arguments.text & chr( 10 );
				if ( len( arguments.color ) ) {
					colorsBuffer.value.append( arguments.color );
				}
				return mock;
			},
			"toConsole" : function(){
				return mock;
			},
			"boldCyanLine" : function( text ){
				outputBuffer.value &= arguments.text & chr( 10 );
				colorsBuffer.value.append( "boldCyan" );
				return mock;
			},
			"boldWhiteLine" : function( text ){
				outputBuffer.value &= arguments.text & chr( 10 );
				colorsBuffer.value.append( "boldWhite" );
				return mock;
			},
			"boldGreenLine" : function( text ){
				outputBuffer.value &= arguments.text & chr( 10 );
				colorsBuffer.value.append( "boldGreen" );
				return mock;
			},
			"getOutput" : function(){
				return outputBuffer.value;
			},
			"getColors" : function(){
				return colorsBuffer.value;
			}
		};
		return mock;
	}

}
