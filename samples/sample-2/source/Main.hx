package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.FlxModding;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptModule;
import flixel.util.FlxScriptUtil;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		FlxModding.init();
		addChild(new FlxGame(0, 0, PlayState));
		/*var scriptModule:FlxScriptModule = FlxScriptUtil.cachedScriptModules.get("assets.data.PlayState");
			var scriptClass:FlxScriptClass = scriptModule.classes.get("PlayState");

			var scriptState:FlxState = scriptClass.callFunction("new", []);

			FlxG.switchState(() -> scriptState);
			scriptClass.callFunction("create", []); */
	}
}
