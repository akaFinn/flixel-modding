package haxe;

using StringTools;

/**
	Cross-platform Ini API.

	@see https://en.wikipedia.org/wiki/INI_file
**/
class Ini
{
	/**
	 * Stores the INI contents.
	 * Outer map: section name → map of key-value pairs.
	 * Inner map: key → value.
	 */
	public var contents:Map<String, Map<String, String>>;

	public function new()
	{
		contents = new Map<String, Map<String, String>>();
	}

	/**
	 * Retrieves a value from a given section and key.
	 * Returns null if the section or key does not exist.
	 */
	public function getValue(section:String, key:String):String
	{
		var sectionMap = contents.get(section.toLowerCase());
		if (sectionMap != null)
			return sectionMap.get(key.toLowerCase());
		return null;
	}

	/**
	 * Sets a value for a given section and key.
	 * Creates the section if it does not exist.
	 */
	public function setValue(section:String, key:String, value:String):Void
	{
		var sectionMap = contents.get(section.toLowerCase());
		if (sectionMap == null)
		{
			sectionMap = new Map<String, String>();
			contents.set(section.toLowerCase(), sectionMap);
		}
		sectionMap.set(key.toLowerCase(), value);
	}

	/**
	 * Parses an INI-formatted string into an Ini instance.
	 * Blank lines and comment lines (starting with ';' or '#') are ignored.
	 * Section and key names are case-insensitive.
	 */
	public static function parse(text:String):Ini
	{
		var ini = new Ini();
		var lines = text.split("\n");

		var currentSection:String = "default";

		for (line in lines)
		{
			var trimmed = line.trim();

			if (trimmed == "" || trimmed.startsWith(";") || trimmed.startsWith("#"))
				continue;

			if (trimmed.startsWith("[") && trimmed.endsWith("]"))
			{
				currentSection = trimmed.substr(1, trimmed.length - 2).trim();
				continue;
			}

			var eqIndex = trimmed.indexOf("=");
			if (eqIndex > 0)
			{
				var key = trimmed.substr(0, eqIndex).trim();
				var value = trimmed.substr(eqIndex + 1).trim();
				ini.setValue(currentSection, key, value);
			}
		}

		return ini;
	}

	/**
	 * Converts this Ini instance into a valid INI-formatted string.
	 * Preserves comments and section order.
	 */
	public static function stringify(ini:Ini):String
	{
		var output:StringBuf = new StringBuf();

		for (section in ini.contents.keys())
		{
			output.add("[" + section + "]\n");
			var sectionMap = ini.contents.get(section);
			for (key in sectionMap.keys())
			{
				var value = sectionMap.get(key);
				output.add(key + " = " + value + "\n");
			}
			output.add("\n"); // Add a blank line between sections
		}

		return output.toString().trim();
	}

	/**
	 * Returns a readable summary of the INI contents.
	 */
	function toString():String
	{
		var output:StringBuf = new StringBuf();

		for (section in contents.keys())
		{
			output.add("[" + section + "]\n");
			var sectionMap = contents.get(section);
			for (key in sectionMap.keys())
				output.add("  " + key + " = " + sectionMap.get(key) + "\n");
		}

		return output.toString().trim();
	}
}
