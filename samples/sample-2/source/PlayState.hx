package;

import flixel.FlxState;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptModule;
import flixel.util.FlxScriptUtil;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();

		/*var scriptModule:FlxScriptModule = FlxScriptUtil.cachedScriptModules.get("assets.data.BasicModule");
			var scriptClass:FlxScriptClass = scriptModule.classes.get("BasicClass");

			var object = scriptClass.callFunction("new", ["Cool Awesome Text"]);
			object.traceText();

			scriptClass.callFunction("buildClass"); */

		FlxScriptUtil.callFunction("assets.data.Module", "TestClass", "main", []);
		FlxScriptUtil.callFunction("assets.data.Module", "TestClass", "mega", ["Hello Parameter World!"]);

		trace(FlxScriptUtil.getClassesExtending(flixel.FlxSprite));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
