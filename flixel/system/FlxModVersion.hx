package flixel.system;

import flixel.system.FlxBaseVersion.FlxVersionBranch;

class FlxModVersion extends FlxBaseVersion
{
    public function new(Major:Int, Minor:Int, Patch:Int, ?Branch:FlxVersionBranch = NONE)
    {
        super(Major, Minor, Patch, Branch, 'FlxModding');
    }    
}