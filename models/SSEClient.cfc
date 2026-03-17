/**
 *********************************************************************************
 * Copyright Since 2014 CommandBox by Ortus Solutions, Corp
 * www.testbox.run | www.boxlang.io | www.ortussolutions.com
 ********************************************************************************
 * Service for consuming Server-Sent Events (SSE) streams from TestBox
 * Parses SSE format and invokes callbacks for each event type
 */
component singleton {

	property name="shell" inject="shell";

	/**
	 * Consume an SSE stream from a URL
	 *
	 * @url           The URL to stream from (should have streaming=true)
	 * @eventHandlers A struct of callbacks keyed by event type (e.g., bundleStart, specEnd, testRunEnd)
	 * @onError       Callback for connection errors
	 *
	 * @return The final testRunEnd event data containing full results, or empty struct on error
	 */
	public struct function consumeStream(
		required string url,
		required struct eventHandlers,
		any onError
	){
		var finalResults = {};
		var reader       = javacast( "null", "" );
		var inputStream  = javacast( "null", "" );
		var connection   = javacast( "null", "" );

		try {
			// Create URL connection
			var netURL = createObject( "java", "java.net.URL" ).init( arguments.url );
			connection = netURL.openConnection();

			connection.setRequestProperty( "Accept", "text/event-stream" );
			connection.setRequestProperty(
				"User-Agent",
				"Mozilla/5.0 (Compatible MSIE 9.0;Windows NT 6.1;WOW64; Trident/5.0)"
			);
			connection.setConnectTimeout( 30000 );
			connection.setReadTimeout( 0 ); // No read timeout for streaming

			connection.connect();

			// Check response code
			if ( connection.responseCode < 200 || connection.responseCode > 299 ) {
				throw(
					message = "HTTP Error: #connection.responseCode# #connection.responseMessage#",
					detail  = arguments.url
				);
			}

			// Read the stream line by line
			inputStream = connection.getInputStream();
			reader      = createObject( "java", "java.io.BufferedReader" ).init(
				createObject( "java", "java.io.InputStreamReader" ).init( inputStream, "UTF-8" )
			);

			var currentEvent = "";
			var currentData  = "";

			while ( true ) {
				// Check for user interrupt
				shell.checkInterrupted();

				var line = reader.readLine();

				// End of stream
				if ( isNull( line ) ) {
					// Process any buffered event if stream ends without trailing blank line
					if ( len( currentEvent ) && len( currentData ) ) {
						processEvent(
							eventType     = currentEvent,
							eventData     = currentData,
							eventHandlers = arguments.eventHandlers,
							finalResults  = finalResults
						);
					}
					break;
				}

				// Parse SSE format
				if ( line.startsWith( "event:" ) ) {
					currentEvent = trim( line.mid( 7, len( line ) ) );
				} else if ( line.startsWith( "data:" ) ) {
					currentData = trim( line.mid( 6, len( line ) ) );
				} else if ( line == "" && len( currentEvent ) && len( currentData ) ) {
					// Empty line signals end of event - process it
					processEvent(
						eventType     = currentEvent,
						eventData     = currentData,
						eventHandlers = arguments.eventHandlers,
						finalResults  = finalResults
					);

					// Reset for next event
					currentEvent = "";
					currentData  = "";
				}
			}
		} catch ( any e ) {
			if ( !isNull( arguments.onError ) && isClosure( arguments.onError ) ) {
				arguments.onError( e );
			} else {
				rethrow;
			}
		} finally {
			// Clean up resources
			try {
				if ( !isNull( reader ) ) {
					reader.close();
				}
			} catch ( any ignore ) {
			}
			try {
				if ( !isNull( inputStream ) ) {
					inputStream.close();
				}
			} catch ( any ignore ) {
			}
			try {
				if ( !isNull( connection ) ) {
					connection.disconnect();
				}
			} catch ( any ignore ) {
			}
		}

		return finalResults;
	}

	/**
	 * Process a single SSE event
	 */
	private function processEvent(
		required string eventType,
		required string eventData,
		required struct eventHandlers,
		required struct finalResults
	){
		// Parse JSON data
		var data = {};
		if ( isJSON( arguments.eventData ) ) {
			data = deserializeJSON( arguments.eventData );
		}

		// If this is the final event, capture the full results
		if ( arguments.eventType == "testRunEnd" && structKeyExists( data, "results" ) ) {
			structAppend(
				arguments.finalResults,
				data.results,
				true
			);
		}

		// Call the appropriate handler if one exists
		if (
			structKeyExists(
				arguments.eventHandlers,
				arguments.eventType
			)
		) {
			var handler = arguments.eventHandlers[ arguments.eventType ];
			if ( isClosure( handler ) ) {
				handler( data );
			}
		}

		// Also call a generic "onEvent" handler if present
		if ( structKeyExists( arguments.eventHandlers, "onEvent" ) ) {
			var handler = arguments.eventHandlers[ "onEvent" ];
			if ( isClosure( handler ) ) {
				handler( arguments.eventType, data );
			}
		}
	}

}
