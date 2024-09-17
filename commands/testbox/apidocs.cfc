/**
 * Open the TestBox API Docs in a browser
 * .
 * {code:bash}
 * testbox apidocs
 * {code}
 **/
component {

	function init(){
	}

	/**
	 * Run the command
	 *
	 **/
	function run(){
		var docsUri = "https://apidocs.ortussolutions.com/##/testbox";
		command( "browse" ).params( uri: docsUri ).run();
	}

}
