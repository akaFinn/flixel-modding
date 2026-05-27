package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.system.FlxModding;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var lowestPitch:Float = #if !web 0 #else 0.1 #end;

	public function new()
	{
		super();

		FlxModding.init();
		FlxModding.system.addBlacklistedDirectory("assets/images/bf-icon.png");
		FlxSprite.defaultAntialiasing = true;

		// addChild(new FlxGame(0, 0, PlayState));
		addChild(new FlxGame(0, 0, PlayState));
		FlxG.mouse.visible = false;
	}
}
