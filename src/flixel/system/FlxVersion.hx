package flixel.system;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
@:build(flixel.system.macros.FlxGitSHA.buildGitSHA("flixel"))
class FlxVersion extends FlxBaseVersion
{
	public function new(Major:Int, Minor:Int, Patch:Int)
	{
		super(Major, Minor, Patch, NONE, 'HaxeFlixel');
	}

	/**
	 * Formats the version in the format "HaxeFlixel MAJOR.MINOR.PATCH-COMMIT_SHA",
	 * e.g. HaxeFlixel 3.0.4.
	 * If this is a dev version, the git sha is included.
	 */
	override public function toString():String
	{
		var sha = FlxVersion.sha;
		if (sha != "")
		{
			sha = "@" + sha.substring(0, 7);
		}

		return 'HaxeFlixel $major.$minor.$patch$sha';
	}
}
