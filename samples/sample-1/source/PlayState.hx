package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	public static var health:Float = 1;
	public static var boyfriend:FlxSprite;

	static var offsets:Map<String, Array<Float>>;

	var stageCamera:FlxCamera;
	var hudCamera:FlxCamera;

	var boyfriendIcon:FlxSprite;
	var boyfriendShader:Shader;

	var stage:FlxGroup;
	var widgets:FlxTypedGroup<ModWidget>;

	var healthLerp:Float = 1;
	var healthBar:FlxBar;

	var bfVocals:FlxSound;
	var dadVocals:FlxSound;

	var switchingState:Bool = false;

	var blueFade:BlueFade = new BlueFade();

	override public function create()
	{
		super.create();

		bfVocals = new FlxSound().loadEmbedded("assets/music/Voices-bf.ogg");
		dadVocals = new FlxSound().loadEmbedded("assets/music/Voices-dad.ogg");

		offsets = new Map<String, Array<Float>>();

		for (offsetText in Assets.getText("assets/data/bf-offsets.txt").split("\n"))
		{
			var animationName:String = offsetText.split("=")[0];

			var offsetNumbers:String = offsetText.split("=")[1];
			var splitNumbers:Array<String> = offsetNumbers.split(",");

			offsets.set(animationName, [Std.parseFloat(splitNumbers[0]), Std.parseFloat(splitNumbers[1])]);
		}

		buildCameras();

		buildStage();
		buildBoyfriend();
		buildHud();

		FlxG.camera.target = boyfriend;
		FlxG.camera.targetOffset.set(-170, -140);
		FlxG.camera.zoom = 0.85;

		FlxG.sound.playMusic("assets/music/Inst.ogg", 1, false);

		dadVocals.play();
		bfVocals.play();
	}

	var lastMousePos:FlxPoint = FlxPoint.get();
	var isDragging:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		health = FlxMath.bound(health, 0, 2);
		healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
		boyfriendIcon.x = ((healthBar.x + healthBar.width) - (healthBar.width * (healthLerp / 2))) - (boyfriendIcon.width / 2);

		if (FlxG.sound.music != null && switchingState != true)
		{
			bfVocals.volume = FlxG.sound.music.volume;
			dadVocals.volume = FlxG.sound.music.volume;
		}

		if (healthBar.percent < 20)
			boyfriendIcon.animation.curAnim.curFrame = 1;
		else
			boyfriendIcon.animation.curAnim.curFrame = 0;

		if (FlxG.mouse.wheel != 0)
		{
			var zoomStep:Float = 0.05;

			if (FlxG.mouse.wheel > 0)
				FlxG.camera.zoom += zoomStep;

			else if (FlxG.mouse.wheel < 0)
				FlxG.camera.zoom -= zoomStep;

			FlxG.camera.zoom = Math.max(0.1, Math.min(FlxG.camera.zoom, 3));
		}

		if (FlxG.keys.justPressed.ENTER && switchingState != true)
		{
			switchingState = true;
			FlxG.sound.play("assets/sounds/confirmMenu.ogg");

			FlxTween.tween(bfVocals, {pitch: 0, volume: 0}, 3, {ease: FlxEase.quartOut});
			FlxTween.tween(dadVocals, {pitch: 0, volume: 0}, 3, {ease: FlxEase.quartOut});
			FlxTween.tween(FlxG.sound.music, {pitch: 0, volume: 0}, 3, {ease: FlxEase.quartOut});

			FlxTimer.wait(0.5, () -> 
			{
				blueFade.fade(1.0, 0.0, 1, {ease: FlxEase.quadIn});
				FlxTween.tween(stageCamera.scroll, {y: stageCamera.scroll.y - 400}, 1, {ease: FlxEase.quadIn});
				FlxTween.tween(hudCamera.scroll, {y: hudCamera.scroll.y - 150}, 1, {ease: FlxEase.quadIn});
			});
		}
	}

	public static function updateBoyfriendOffsets():Void
	{
		boyfriend.offset.set(offsets.get(boyfriend.animation.curAnim.name)[0], offsets.get(boyfriend.animation.curAnim.name)[1]);	
	}

	function updateBoyfriendPosition():Void
	{
		boyfriend.setPosition(1007.5 - (boyfriend.width / 2), 895 - boyfriend.height);
	}

	function buildStage():Void
	{
		stage = new FlxGroup();
		stage.cameras = [stageCamera];

		var brightLightSmall = new FlxSprite();
		brightLightSmall.loadGraphic("assets/images/stage/brightLightSmall.png");
		brightLightSmall.scrollFactor.set(1.2, 1.2);
		brightLightSmall.setPosition(967, -103);
		stage.add(brightLightSmall);

		var crowd = new FlxSprite();
		crowd.frames = FlxAtlasFrames.fromSparrow("assets/images/stage/crowd.png", "assets/images/stage/crowd.xml");
		crowd.animation.addByPrefix("idle", "idle0", 12);
		crowd.scrollFactor.set(0.8, 0.8);
		crowd.animation.play("idle");
		crowd.setPosition(682, 290);
		stage.add(crowd);

		var bg = new FlxSprite();
		bg.loadGraphic("assets/images/stage/bg.png");
		bg.setPosition(-765, -247);
		stage.add(bg);

		var server = new FlxSprite();
		server.loadGraphic("assets/images/stage/server.png");
		server.setPosition(-991, 205);
		stage.add(server);

		var lights = new FlxSprite();
		lights.loadGraphic("assets/images/stage/lights.png");
		lights.scrollFactor.set(1.2, 1.2);
		lights.setPosition(-847, -245);
		stage.add(lights);

		var orangeLight = new FlxSprite();
		orangeLight.loadGraphic("assets/images/stage/orangeLight.png");
		orangeLight.scale.set(1, 1700);
		orangeLight.updateHitbox();
		orangeLight.setPosition(189, -500);
		stage.add(orangeLight);

		var lightgreen = new FlxSprite();
		lightgreen.loadGraphic("assets/images/stage/lightgreen.png");
		lightgreen.setPosition(-171, 242);
		stage.add(lightgreen);

		var lightred = new FlxSprite();
		lightred.loadGraphic("assets/images/stage/lightred.png");
		lightred.setPosition(-101, 560);
		stage.add(lightred);

		var lightAbove = new FlxSprite();
		lightAbove.loadGraphic("assets/images/stage/lightAbove.png");
		lightAbove.setPosition(804, -117);
		stage.add(lightAbove);

		add(stage);
	}

	function buildCameras():Void
	{
		stageCamera = new FlxCamera();
		stageCamera.filters = [new ShaderFilter(blueFade)];
		FlxG.cameras.reset(stageCamera);
		
		hudCamera = new FlxCamera();
		hudCamera.filters = [new ShaderFilter(blueFade)];
		hudCamera.bgColor.alpha = 1;
		FlxG.cameras.add(hudCamera, false);
	}

	function buildBoyfriend():Void
	{
		boyfriendShader = new Shader();
		boyfriendShader.brightness = -23;
		boyfriendShader.hue = 12;
		boyfriendShader.contrast = 7;
		boyfriendShader.saturation = 0;

		boyfriend = new FlxSprite();
		boyfriend.frames = FlxAtlasFrames.fromSparrow("assets/images/boyfriend.png", "assets/images/boyfriend.xml");
		boyfriend.animation.addByPrefix("idle", "BF idle dance", 24, false);
		boyfriend.animation.addByPrefix("left", "BF NOTE LEFT0", 24, false);
		boyfriend.animation.addByPrefix("down", "BF NOTE DOWN0", 24, false);
		boyfriend.animation.addByPrefix("up", "BF NOTE UP0", 24, false);
		boyfriend.animation.addByPrefix("right", "BF NOTE RIGHT0", 24, false);
		boyfriend.animation.play("idle");
		boyfriend.shader = boyfriendShader;
		updateBoyfriendPosition();
		updateBoyfriendOffsets();

		boyfriend.animation.onFinish.add((name:String) -> {
			boyfriend.animation.play("idle"); 
			updateBoyfriendOffsets();
		});

		stage.add(boyfriend);
	}

	function buildHud():Void
	{
		var strumline = new Strumline(50, 50);
		strumline.loadChart(Assets.getText("assets/data/song-data.json"));
		strumline.cameras = [hudCamera];
		add(strumline);

		var healthBarBg = new FlxSprite();
		healthBarBg.loadGraphic("assets/images/healthBar.png");
		healthBarBg.setPosition(50, FlxG.height - (healthBarBg.height + 30));
		healthBarBg.cameras = [hudCamera];
		add(healthBarBg);

		var header = new FlxText(4, 4);
		header.text = "Press 'ENTER' to open Mods";
		header.setFormat("assets/fonts/vcr.ttf", 20);
		header.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		header.cameras = [hudCamera];
		add(header);

		healthBar = new FlxBar(healthBarBg.x + 4, healthBarBg.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBg.width - 8), Std.int(healthBarBg.height - 8), this, "healthLerp", 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		healthBar.numDivisions = 999999999;
		healthBar.cameras = [hudCamera];
		add(healthBar);

		boyfriendIcon = new FlxSprite();
		boyfriendIcon.loadGraphic("assets/images/bf-icon.png", true, 150, 150);
		boyfriendIcon.animation.add("static", [0, 1], 0, false);
		boyfriendIcon.animation.play("static");
		boyfriendIcon.flipX = true;
		boyfriendIcon.setPosition(((healthBar.x + healthBar.width) - (healthBar.width * (healthLerp / 2))) - (boyfriendIcon.width / 2), (healthBar.y + (healthBar.height / 2)) - (boyfriendIcon.height / 2));
		boyfriendIcon.cameras = [hudCamera];
		add(boyfriendIcon);
	}
}
