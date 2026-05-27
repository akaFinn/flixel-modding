package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxScriptUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	public static var health:Float = 1;
	public static var boyfriend:FlxSprite;
	public static var score:Float;

	static var offsets:Map<String, Array<Float>>;

	var stageCamera:FlxCamera;
	var hudCamera:FlxCamera;

	var boyfriendIcon:FlxSprite;
	var boyfriendShader:Shader;

	var healthLerp:Float = 1;
	var healthBar:FlxBar;
	var scoreText:FlxText;
	var header:FlxText;

	public static var bfVocals:FlxSound;
	public static var dadVocals:FlxSound;

	var switchingState:Bool = false;

	var blueFade:BlueFade = new BlueFade();

	override public function create()
	{
		bfVocals = new FlxSound().loadEmbedded("assets/music/Voices-bf.ogg");
		dadVocals = new FlxSound().loadEmbedded("assets/music/Voices-dad.ogg");

		// super.create();

		var scriptStateClass = FlxScriptUtil.getScriptClass('ScriptedState');
		scriptStateClass.scriptStaticCall('printMessage', ['Hello, World']);
		scriptStateClass.scriptStaticSet('defaultMessage', 'Default Text!');
		scriptStateClass.scriptStaticGet('defaultMessage');

		var scriptState = scriptStateClass.scriptNew();
		// Reflect.callMethod(scriptState, Reflect.field(scriptState, 'scriptCall'), []);
		FlxG.switchState(() -> scriptState);

		offsets = new Map<String, Array<Float>>();

		for (offsetText in Assets.getText("assets/data/bf-offsets.txt").split("\n"))
		{
			var animationName:String = offsetText.split("=")[0];

			var offsetNumbers:String = offsetText.split("=")[1];
			var splitNumbers:Array<String> = offsetNumbers.split(",");

			offsets.set(animationName, [Std.parseFloat(splitNumbers[0]), Std.parseFloat(splitNumbers[1])]);
		}

		buildCameras();

		// buildStage();
		buildBoyfriend();
		buildHud();

		health = 1;
		score = 0;

		FlxG.camera.target = boyfriend;
		FlxG.camera.targetOffset.set(-370, -140);
		FlxG.camera.zoom = 0.85;

		FlxG.sound.playMusic("assets/music/Inst.ogg", 0, false);
		FlxG.sound.music.pitch = Main.lowestPitch;

		dadVocals.play();
		dadVocals.pitch = Main.lowestPitch;

		bfVocals.play();
		bfVocals.pitch = Main.lowestPitch;

		FlxTween.tween(FlxG.sound.music, {pitch: 1, volume: 1}, 0.5, {ease: FlxEase.quartIn});
		FlxTween.tween(dadVocals, {pitch: 1, volume: 1}, 0.5, {ease: FlxEase.quartIn, onComplete: (tween) -> {dadVocals.time = FlxG.sound.music.time;}});
		FlxTween.tween(bfVocals, {pitch: 1, volume: 1}, 0.5, {ease: FlxEase.quartIn, onComplete: (tween) -> {bfVocals.time = FlxG.sound.music.time;}});

		hudCamera.scroll.subtract(250, 0);

		blueFade.fade(0, 1, 0.5, {ease: FlxEase.quartOut});
		FlxTween.tween(FlxG.camera.targetOffset, {x: FlxG.camera.targetOffset.x + 200}, 0.5, {ease: FlxEase.quartOut});
		FlxTween.tween(hudCamera.scroll, {x: hudCamera.scroll.x + 250}, 0.5, {ease: FlxEase.quartOut});

		FlxG.signals.focusLost.add(() ->
		{
			dadVocals.pause();
			bfVocals.pause();
		});

		FlxG.signals.focusGained.add(() ->
		{
			dadVocals.time = FlxG.sound.music.time;
			bfVocals.time = FlxG.sound.music.time;

			dadVocals.resume();
			bfVocals.resume();
		});

		FlxG.sound.onVolumeChange.add((f:Float) -> {
			bfVocals.volume = FlxG.sound.music.volume;
			dadVocals.volume = FlxG.sound.music.volume;
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		this.updateVocals(elapsed);

		health = FlxMath.bound(health, 0, 2);
		healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
		boyfriendIcon.x = ((healthBar.x + healthBar.width) - (healthBar.width * (healthLerp / 2))) - (boyfriendIcon.width / 2);

		scoreText.text = "Score:" + FlxStringUtil.formatMoney(score, false);

		if (healthBar.percent < 20)
			boyfriendIcon.animation.curAnim.curFrame = 1;
		else
			boyfriendIcon.animation.curAnim.curFrame = 0;

		#if DEBUG_CONTROLS
		if (FlxG.mouse.wheel != 0)
		{
			var zoomStep:Float = 0.05;

			if (FlxG.mouse.wheel > 0)
				FlxG.camera.zoom += zoomStep;

			else if (FlxG.mouse.wheel < 0)
				FlxG.camera.zoom -= zoomStep;

			FlxG.camera.zoom = Math.max(0.1, Math.min(FlxG.camera.zoom, 3));
		}

		if (FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.justPressed.R)
			{
				dadVocals.stop();
				bfVocals.stop();

				FlxG.resetState();
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				@:privateAccess
				if (FlxG.sound.music._paused != true)
				{
					FlxG.sound.music.pause();
					bfVocals.pause();
					dadVocals.pause();
				}
				else
				{
					FlxG.sound.music.resume();
					bfVocals.resume();
					dadVocals.resume();

					bfVocals.time = FlxG.sound.music.time;
					dadVocals.time = FlxG.sound.music.time;
				}
			}

			if (FlxG.keys.pressed.UP)
			{
				FlxG.sound.music.time += 15;
			}

			if (FlxG.keys.pressed.DOWN)
			{
				FlxG.sound.music.time -= 15;
			}
		}
		#end

		if (FlxG.keys.justPressed.TAB && switchingState != true)
		{
			switchingState = true;
			FlxG.sound.play("assets/sounds/confirmMenu.ogg");

			FlxTween.tween(bfVocals, {pitch: Main.lowestPitch, volume: 0}, 3, {ease: FlxEase.quartOut});
			FlxTween.tween(dadVocals, {pitch: Main.lowestPitch, volume: 0}, 3, {ease: FlxEase.quartOut});
			FlxTween.tween(FlxG.sound.music, {pitch: Main.lowestPitch, volume: 0}, 3, {ease: FlxEase.quartOut});

			FlxTween.color(header, 0.4, FlxColor.CYAN, FlxColor.WHITE);

			FlxTimer.wait(0.5, () -> 
			{
				blueFade.fade(1.0, 0.0, 1, {ease: FlxEase.quadIn});
				FlxTween.tween(FlxG.camera.targetOffset, {x: FlxG.camera.targetOffset.x - 200}, 1, {ease: FlxEase.quadIn});
				FlxTween.tween(hudCamera.scroll, {x: hudCamera.scroll.x - 250}, 1, {ease: FlxEase.quadIn});
			});

			FlxTimer.wait(3, () ->
			{
				FlxG.switchState(() -> new ModsState());
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
		/*var mainStage:FlxScriptObject = FlxScriptUtil.getScriptClass('MainStage').scriptNew();
		mainStage.functions.call('printCrap');
		add(mainStage.getSuperObj());*/
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

		add(boyfriend);
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

		header = new FlxText(4, 4);
		header.text = "Press 'TAB' to open Mods";
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

		scoreText = new FlxText();
		scoreText.x = healthBarBg.x + healthBarBg.width - 190;
		scoreText.y = healthBarBg.y + 30;
		scoreText.setFormat("assets/fonts/vcr.ttf", 15);
		scoreText.alignment = RIGHT;
		scoreText.borderStyle = OUTLINE;
		scoreText.borderColor = FlxColor.BLACK;
		scoreText.letterSpacing = -1;
		scoreText.cameras = [hudCamera];
		add(scoreText);
	}

	function updateVocals(elapsed:Float):Void
	{
		bfVocals.update(elapsed);
		dadVocals.update(elapsed);
	}
}
