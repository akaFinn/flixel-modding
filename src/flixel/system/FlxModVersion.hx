package flixel.system;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
class FlxModVersion extends FlxBaseVersion
{
	public function new(Major:Int, Minor:Int, Patch:Int)
	{
		super(Major, Minor, Patch, BETA, 'FlxModding');
	}
}