/** Acknowledge terminal interrupts without abandoning the coordinator's cleanup stream. */
component {

	function init(
		required any renderer,
		required string url
	){
		variables.renderer = arguments.renderer;
		variables.url      = reReplaceNoCase(
			arguments.url,
			"([?&])action=run(?=&|$)",
			"\1action=cancel"
		);
		variables.requested = false;
		variables.identity  = "TestBoxParallelInterrupt-" & createUUID();
		return this;
	}

	numeric function hashCode(){
		return createObject( "java", "java.lang.String" ).init( variables.identity ).hashCode();
	}

	string function toString(){
		return variables.identity;
	}

	boolean function equals( required any other ){
		return !isNull( arguments.other ) && arguments.other.toString() == variables.identity;
	}

	function wrapPrevious( required any handler ){
		// Lucee hashes Java arguments while unwrapping them. CommandBox's original
		// signal proxy has no hashCode implementation; unwrap it without hashing it.
		variables.previousHandler = arguments.handler;
		return createDynamicProxy(
			this,
			[ "lucee.runtime.type.ObjectWrap" ]
		);
	}

	function getEmbededObject( any defaultValue ){
		return variables.previousHandler;
	}

	function handle( required any signal ){
		if (
			!listFind(
				"INT,SIGINT",
				arguments.signal.toString()
			)
		) {
			return;
		}
		requestCancellation( "Ctrl-C received; stopping workers gracefully (30s maximum)" );
	}

	function requestCancellation( required string message ){
		lock name="testbox-interrupt-#hash( variables.url )#" type="exclusive" timeout=10 {
			if ( variables.requested ) {
				return;
			}
			variables.requested = true;
		}
		variables.renderer.handleEvent(
			"runCancelling",
			{ "message" : arguments.message }
		);
		var connection = createObject( "java", "java.net.URL" ).init( variables.url ).openConnection();
		try {
			connection.setRequestMethod( "POST" );
			connection.setConnectTimeout( 5000 );
			connection.setReadTimeout( 5000 );
			if ( connection.getResponseCode() != 200 ) {
				throw( message = "Cancellation request was rejected" );
			}
		} catch ( any error ) {
			variables.renderer.abort( "Failed" );
			// Keep the failure visible; never claim remote workers stopped.
			systemOutput(
				"Cancellation could not reach the runner: " & error.message,
				true
			);
		} finally {
			connection.disconnect();
		}
	}

}
