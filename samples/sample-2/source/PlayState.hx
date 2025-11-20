package;

import flixel.FlxState;
import flixel.util.FlxScriptUtil;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();
		
		var file:String = "assets/data/Module.hxc";
		var text:String = Assets.getText(file);

		var script = FlxScriptUtil.buildScriptModule(file, text);
		script.callFunction("TestClass1", "main", []);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
