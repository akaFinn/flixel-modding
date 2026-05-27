package;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxBaseModpack;
import flixel.system.FlxFileSystem;
import flixel.system.FlxModding;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;
import openfl.net.FileFilter;
import openfl.net.FileReference;

class ModsState extends FlxState
{
	var blueFade:BlueFade = new BlueFade();

	var labels:FlxTypedSpriteGroup<Alphabet>;

	var selectables:Array<Alphabet>;
	var selectionIndex:Int;
	var canSelect:Bool;

    override function create()
    {
        super.create();
		FlxG.cameras.reset();
		FlxG.camera.scroll.set(550, 200);
		FlxG.camera.filters = [new ShaderFilter(blueFade)];

        buildStage();
		buildBoyfriend();
		buildHud();

		FlxG.sound.playMusic("assets/music/stayFunky.ogg", 0, true);
		FlxG.sound.music.pitch = Main.lowestPitch;

		blueFade.fade(0, 1, 0.5, {ease: FlxEase.quadIn});
		FlxTween.tween(FlxG.camera.scroll, {x: 450}, 2, {ease: FlxEase.quartOut});
		FlxTween.tween(FlxG.sound.music, {pitch: 1, volume: 1}, 1, {ease: FlxEase.quartOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP)
		{
			changeSelection(-1);
		}

		if (FlxG.keys.justPressed.DOWN)
		{
			changeSelection(1);
		}

		if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) && canSelect != false)
		{
			FlxG.sound.play("assets/sounds/confirmMenu.ogg");

			switch (selectionIndex)
			{
				case 0:
					canSelect = false;

					FlxG.sound.play("assets/sounds/confirmMenu.ogg");
					FlxTween.tween(FlxG.sound.music, {pitch: Main.lowestPitch, volume: 0}, 3, {ease: FlxEase.quartOut});

					FlxTimer.wait(0.5, () -> 
					{
						blueFade.fade(1.0, 0.0, 1, {ease: FlxEase.quadIn});
						FlxTween.tween(FlxG.camera.scroll, {x: FlxG.camera.scroll.x + 100}, 1, {ease: FlxEase.quadIn});
					});

					FlxTimer.wait(3, () ->
					{
						FlxG.switchState(() -> new PlayState());
					});

				case 1:
					FlxModding.reload();
					FlxG.resetState();

				case 2:
					function onSelect(fileReference:FileReference):Void
					{
						fileReference.load();
					}

					function onComplete(fileReference:FileReference):Void
					{
						FlxModding.unzip(fileReference.data);
						FlxG.resetState();
					}

					FlxFileSystem.browseFiles([new FileFilter("Zip files", "*.zip")], (e) -> onSelect(e), (e) -> onComplete(e));

				default:
					var modpack:FlxBaseModpack = FlxModding.get(selectables[selectionIndex].text);
					modpack.active = !modpack.active;

					if (modpack.active != true)
						selectables[selectionIndex].alpha = 0.6;
					else
						selectables[selectionIndex].alpha = 1;
			}
		}

		#if DEBUG_CONTROLS
		if (FlxG.keys.justPressed.R)
			FlxG.resetState();

		if (FlxG.mouse.wheel != 0)
		{
			var zoomStep:Float = 0.05;

			if (FlxG.mouse.wheel > 0)
				FlxG.camera.zoom += zoomStep;

			else if (FlxG.mouse.wheel < 0)
				FlxG.camera.zoom -= zoomStep;

			FlxG.camera.zoom = Math.max(0.1, Math.min(FlxG.camera.zoom, 3));
		}
		#end
	}

	function changeSelection(value:Int, ?silent:Bool = false):Void
	{
		selectionIndex += value;

		if (selectionIndex < 0)
			selectionIndex = selectables.length - 1;

		if (selectionIndex > selectables.length - 1)
			selectionIndex = 0;

		for (label in selectables)
		{
			label.setColor(FlxColor.WHITE);
		}

		if (silent != true)
			FlxG.sound.play("assets/sounds/scrollMenu.ogg");

		selectables[selectionIndex].setColor(FlxColor.CYAN);
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

	function buildHud():Void
	{
		selectables = [];
		selectionIndex = 0;
		canSelect = true;

		labels = new FlxTypedSpriteGroup<Alphabet>(1000, 450);
		labels.scrollFactor.set(2, 2);
		add(labels);

		var header = new Alphabet(0, 0, "MOD MENU", true);
		header.setColor(FlxColor.YELLOW);
		labels.add(header);

		var close = new Alphabet(0, 0, "CLOSE MENU", true);
		close.setPosition(0, header.height * 2);
		labels.add(close);
		selectables.push(close);

		var reload = new Alphabet(0, 0, "RELOAD MENU", true);
		reload.setPosition(0, header.height * 3);
		labels.add(reload);
		selectables.push(reload);

		var unzip = new Alphabet(0, 0, "UNZIP MODPACK", true);
		unzip.setPosition(0, header.height * 4);
		labels.add(unzip);
		selectables.push(unzip);

		changeSelection(0, true);

		for (modpack in FlxModding.modpacks)
		{
			@:privateAccess
			var modpackLabel = new Alphabet(0, 0, modpack.fileName, true);
			modpackLabel.setPosition(0, header.height * (3 + selectables.length));
			labels.add(modpackLabel);
			selectables.push(modpackLabel);

			if (modpack.active != true)
				modpackLabel.alpha = 0.6;
		}
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