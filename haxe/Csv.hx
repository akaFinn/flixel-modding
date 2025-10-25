package haxe;

using StringTools;

/**
	Cross-platform Csv API.

	@see https://docs.fileformat.com/web/crt/
**/
class Csv
{
	/**
	 * Stores the CSV contents as a map of maps.
	 * The outer map's key represents the row index (Y).
	 * The inner map's key represents the column index (X).
	 */
	public var contents:Map<Int, Map<Int, String>>;

	/**
	 * Number of rows in the CSV grid.
	 */
	public var rows:Int;

	/**
	 * Number of columns in the CSV grid.
	 */
	public var columns:Int;

	public function new()
	{
		contents = new Map<Int, Map<Int, String>>();
		rows = 0;
		columns = 0;
	}

	/**
	 * Adds a new row to the CSV using an array of values.
	 * The values are stored internally as a map of column indices.
	 */
	public function addRow(values:Array<String>):Void
	{
		var rowIndex = rows + 1;
		var rowMap:Map<Int, String> = new Map();

		for (i in 0...values.length)
			rowMap.set(i + 1, values[i].trim());

		contents.set(rowIndex, rowMap);
		rows++;
		if (values.length > columns)
			columns = values.length;
	}

	/**
	 * Retrieves a cell value using X (column) and Y (row) coordinates.
	 */
	public function getValue(x:Int, y:Int):String
	{
		if (!contents.exists(y))
			return null;
		var row = contents.get(y);
		if (!row.exists(x))
			return null;
		return row.get(x);
	}

	/**
	 * Sets a specific cell value using X (column) and Y (row) coordinates.
	 * Automatically expands the CSV grid if needed.
	 */
	public function setValue(x:Int, y:Int, value:String):Void
	{
		if (!contents.exists(y))
			contents.set(y, new Map<Int, String>());

		var row = contents.get(y);
		row.set(x, value);

		if (y > rows)
			rows = y;
		if (x > columns)
			columns = x;
	}

	/**
	 * Parses a CSV-formatted string into a Csv instance.
	 */
	public static function parse(text:String):Csv
	{
		var csv:Csv = new Csv();
		var normalized = text.replace("\r\n", "\n").replace("\r", "\n");
		var lines = normalized.split("\n");

		for (line in lines)
		{
			if (line.trim() == "")
				continue;

			var row = [for (v in line.split(",")) v.trim()];
			csv.addRow(row);
		}

		return csv;
	}

	/**
	 * Returns this CSV as a valid CSV-formatted string.
	 */
	public static function stringify(csv:Csv):String
	{
		var output:StringBuf = new StringBuf();

		for (y in 1...csv.rows + 1)
		{
			var row = csv.contents.get(y);
			var line:Array<String> = [];
			for (x in 1...csv.columns + 1)
				line.push(row != null && row.exists(x) ? row.get(x) : "");
			output.add(line.join(","));
			if (y != csv.rows) output.add("\n");
		}

		return output.toString();
	}

	/**
	 * Returns a human-readable summary of the CSV contents.
	 */
	function toString():String
	{
		var output:StringBuf = new StringBuf();
		output.add('CSV Grid (${columns}x${rows})\n');

		for (y in 1...rows + 1)
		{
			var row = contents.get(y);
			var values:Array<String> = [];

			for (x in 1...columns + 1)
				values.push(row != null && row.exists(x) ? row.get(x) : "");

			output.add('Row $y: ${values.join(" | ")}\n');
		}

		return output.toString().trim();
	}
}
