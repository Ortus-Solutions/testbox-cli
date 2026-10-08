component {

	this.lines = [];

	function line( string text = "" ){
		this.lines.append( text );
		return this;
	}

	function redLine( string text = "" ){
		return line( text );
	}

	function toConsole(){
		return this;
	}

	function table(
		required array data,
		string includedHeaders = "",
		string headerNames     = ""
	){
		this.tableData    = arguments.data;
		this.tableHeaders = arguments.headerNames;
		return this;
	}

}
