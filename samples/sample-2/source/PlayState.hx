package;

import flixel.FlxState;
import flixel.system.hscript.FlxScriptClass;
import flixel.util.FlxScriptUtil;

class PlayState extends FlxState
{
	override public function create()
	{
		var scriptClass:FlxScriptClass = FlxScriptUtil.getScriptClass('TestScript');
		scriptClass.s_staticCall('main', []);
		scriptClass.s_staticSet('helloWorld', 'Hello, Other World!');
		scriptClass.s_staticCall('main', [10]);
		scriptClass.s_staticSet('helloWorld', 'Hello, World!');

		// var object = scriptClass.s_new(['John Doe']);
		// object.sayHello();
		// object.name = 'Jane Doe';
		// object.sayHello();
		// add(object);

		// trace(object);
		trace(scriptClass);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
