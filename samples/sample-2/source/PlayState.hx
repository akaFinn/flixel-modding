package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptModule;
import flixel.util.FlxScriptUtil;

class PlayState extends FlxState
{
	override public function create()
	{
		var scriptClass:FlxScriptClass = FlxScriptUtil.getScriptClass('TestScript');
		scriptClass.scriptStaticCall('main', [5]);
		scriptClass.scriptStaticSet('helloWorld', 'Hello, Other World!');
		scriptClass.scriptStaticCall('main', [10]);
		scriptClass.scriptStaticSet('helloWorld', 'Hello, World!');

		if (scriptClass.superClass != null)
			trace('${scriptClass.name}\'s SuperClass is "${Type.getClassName(scriptClass.superClass)}"');

		var object = scriptClass.scriptNew(['John Doe']);
		// object.sayHello();
		// object.name = 'Jane Doe';
		// object.sayHello();
		add(object);

		trace(object);
		trace(scriptClass);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
