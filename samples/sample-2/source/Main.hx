package;

import flixel.FlxGame;
import flixel.system.FlxModding;
import flixel.util.FlxScriptUtil;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		// FlxModding.init();
		FlxScriptUtil.buildAllScriptModules();
		addChild(new FlxGame(0, 0, PlayState));
	}
}
