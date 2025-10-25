package flixel.system;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
class FlxBaseVersion
{
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):Int;

	public var branch(default, null):FlxVersionBranch;
	public var prefix(default, null):String;

	public function new(Major:Int, Minor:Int, Patch:Int, ?Branch:FlxVersionBranch = NONE, ?Prefix:String = "")
	{
		major = Major;
		minor = Minor;
		patch = Patch;

		branch = Branch;
		
		if (Prefix != "" || Prefix != null)
			prefix = '$Prefix ';
		else
			prefix = '';
	}

	/**
	 * Formats the version in the format "MAJOR.MINOR.PATCH",
	 * e.g. 3.0.4.
	 */
	public function toString():String
	{
		if (branch != NONE || branch != null)
            return '$prefix$major.$minor.$patch-$branch';
        else
            return '$prefix$major.$minor.$patch';
	}
}

enum abstract FlxVersionBranch(String)
{
	var NONE = "none";
	var PROTOTYPE = "prototype";
	var ALPHA = "alpha";
	var BETA = "beta";
}
