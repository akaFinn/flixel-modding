package;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;

class ModsState extends FlxState
{
	var blueFade:BlueFade = new BlueFade();

    override function create()
    {
        super.create();
		FlxG.cameras.reset();
		FlxG.camera.scroll.set(550, 200);
		FlxG.camera.filters = [new ShaderFilter(blueFade)];

        buildStage();
		buildBoyfriend();

		FlxG.sound.playMusic("assets/music/stayFunky.ogg", 0, true);
		FlxG.sound.music.pitch = 0;

		blueFade.fade(0, 1, 0.5, {ease: FlxEase.quadIn});
		FlxTween.tween(FlxG.camera.scroll, {x: 450}, 2, {ease: FlxEase.quartOut});
		FlxTween.tween(FlxG.sound.music, {pitch: 1, volume: 1}, 1, {ease: FlxEase.quartOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if DEBUG_CONTROLS
		if (FlxG.keys.anyPressed([A, LEFT]))
			FlxG.camera.scroll.x -= 10;

		if (FlxG.keys.anyPressed([D, RIGHT]))
			FlxG.camera.scroll.x += 10;

		if (FlxG.keys.anyPressed([W, UP]))
			FlxG.camera.scroll.y -= 10;

		if (FlxG.keys.anyPressed([S, DOWN]))
			FlxG.camera.scroll.y += 10;

		if (FlxG.keys.justPressed.R)
			FlxG.resetState();
		#end
	}

	function buildBoyfriend():Void
	{
		var bf = new FlxAnimate();
		bf.frames = FlxAnimateFrames.fromAnimate("assets/images/bfChill");
		bf.anim.addBySymbol("idle", "bf cs idle", 24, true);
		bf.anim.play("idle");
		bf.scale.set(1.4, 1.4);
		bf.scrollFactor.set(2.6, 0.6);
		bf.setPosition(2000, 450);
		add(bf);
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