/**
 * Open the TestBox Docs in a browser
 * .
 * {code:bash}
 * testbox docs
 * {code}
 * .
 * {code:bash}
 * testbox docs search=handlers
 * {code}
 **/
component {

	function init(){
	}

	/**
	 * Run the command
	 *
	 * @search   A string to search in the docs
	 **/
	function run( string search = "" ){
		var docsUri = "https://testbox.ortusbooks.com" & ( search.len() ? "?q=#search#" : "" );
		command( "browse" ).params( uri: docsUri ).run();
	}

}
