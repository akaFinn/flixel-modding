package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;

class ModsState extends FlxState
{
    override function create()
    {
        super.create();
        buildStage();
    }

    function buildStage():Void
	{
		var brightLightSmall = new FlxSprite();
		brightLightSmall.loadGraphic("assets/images/stage/brightLightSmall.png");
		brightLightSmall.scrollFactor.set(1.2, 1.2);
		brightLightSmall.setPosition(967, -103);
		add(brightLightSmall);

		var crowd = new FlxSprite();
		crowd.frames = FlxAtlasFrames.fromSparrow("assets/images/stage/crowd.png", "assets/images/stage/crowd.xml");
		crowd.animation.addByPrefix("idle", "idle0", 12);
		crowd.scrollFactor.set(0.8, 0.8);
		crowd.animation.play("idle");
		crowd.setPosition(682, 290);
		add(crowd);

		var bg = new FlxSprite();
		bg.loadGraphic("assets/images/stage/bg.png");
		bg.setPosition(-765, -247);
		add(bg);

		var server = new FlxSprite();
		server.loadGraphic("assets/images/stage/server.png");
		server.setPosition(-991, 205);
		add(server);

		var lights = new FlxSprite();
		lights.loadGraphic("assets/images/stage/lights.png");
		lights.scrollFactor.set(1.2, 1.2);
		lights.setPosition(-847, -245);
		add(lights);

		var orangeLight = new FlxSprite();
		orangeLight.loadGraphic("assets/images/stage/orangeLight.png");
		orangeLight.scale.set(1, 1700);
		orangeLight.updateHitbox();
		orangeLight.setPosition(189, -500);
		add(orangeLight);

		var lightgreen = new FlxSprite();
		lightgreen.loadGraphic("assets/images/stage/lightgreen.png");
		lightgreen.setPosition(-171, 242);
		add(lightgreen);

		var lightred = new FlxSprite();
		lightred.loadGraphic("assets/images/stage/lightred.png");
		lightred.setPosition(-101, 560);
		add(lightred);

		var lightAbove = new FlxSprite();
		lightAbove.loadGraphic("assets/images/stage/lightAbove.png");
		lightAbove.setPosition(804, -117);
		add(lightAbove);
	}
}