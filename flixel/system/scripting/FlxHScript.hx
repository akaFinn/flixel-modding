package flixel.system.scripting;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.effects.FlxFlicker;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxContainer;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKeyboard;
import flixel.input.mouse.FlxMouse;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.macros.FlxMacroUtil;
import flixel.text.FlxInputText;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.PosInfos;

#if hscript
import hscript.Interp;
import hscript.Parser;
#end

/**
 * A helper class that simplifies working with HScript inside Flixel.
 * 
 * FlxHScript wraps the basic setup and execution flow for HScript scripts,
 * making it easier to inject variables, run scripts, and integrate scripting support
 * into Flixel-based games. It extends FlxBasic, so it can be added to states
 * and follow the Flixel object lifecycle if needed.
 */
class FlxHScript extends FlxBasic
{
    public static var globalVariables:Map<String, Dynamic>;

    public var code:String;

    #if hscript
    var interp:Interp;
    var parser:Parser;
    #end

    /**
     * Creates a new FlxHScript instance and optionally loads a script from a file path.
     */
    public function new(?path:String)
    {
        #if hscript
        parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;
        interp = new FlxInterp(path);

        super();

        loadGlobals();
        if (path != null) execute(FlxG.assets.getText(path)); 
        #else
        super();

        FlxG.log.warn("Failed to execute FlxHScript, the hscript package is not installed and is required to run FlxHScript.");
        #end
    }

	/**
	 * Executes raw HScript code passed as a string.
	 */
	public function execute(code:String):Void
	{
		#if hscript
		this.code = code;
		interp.execute(parser.parseString(code));
		#end
	}

	/**
	 * Sets a variable inside the HScript environment.
	 */
	public function setVariable(key:String, value:Dynamic):Void
	{
		#if hscript
		interp.variables.set(key, value);
		#end
	}

	/**
	 * Retrieves a variable from the HScript environment.
	 */
	public function getVariable(key:String):Dynamic
	{
		#if hscript
		return interp.variables.get(key);
		#end
	}

    function loadGlobals():Void
    {
        for (globalKey in globalVariables.keys())
        {
            setVariable(globalKey, getGlobalVariable(globalKey));
        }
    }

    static function loadFlixelClasses():Void
    {
        // Basics
        setGlobalVariable("FlxG", FlxG);
        setGlobalVariable("FlxGraphic", FlxGraphic);
        setGlobalVariable("FlxSprite", FlxSprite);
        setGlobalVariable("FlxObject", FlxObject);
        setGlobalVariable("FlxBasic", FlxBasic);
        setGlobalVariable("FlxState", FlxState);
        setGlobalVariable("FlxCamera", FlxCamera);
        setGlobalVariable("FlxGame", FlxGame);

        // Groups
        setGlobalVariable("FlxGroup", FlxGroup);
        setGlobalVariable("FlxContainer", FlxContainer);

        // Animation
        setGlobalVariable("FlxAnimation", FlxAnimation);
        setGlobalVariable("FlxAnimationController", FlxAnimationController);
        setGlobalVariable("FlxAtlasFrames", FlxAtlasFrames);
        setGlobalVariable("FlxTileFrames", FlxTileFrames);
        setGlobalVariable("FlxFrame", FlxFrame);

        // Math
        setGlobalVariable("FlxAngle", FlxAngle);
        setGlobalVariable("FlxRect", FlxRect);
        setGlobalVariable("FlxMath", FlxMath);
        setGlobalVariable("FlxRandom", FlxRandom);

        // Text
        setGlobalVariable("FlxText", FlxText);
        setGlobalVariable("FlxInputText", FlxInputText);

        // Input
        setGlobalVariable("FlxMouse", FlxMouse);
        setGlobalVariable("FlxKeyboard", FlxKeyboard);
        setGlobalVariable("FlxGamepad", FlxGamepad);

        // Utilities
        setGlobalVariable("FlxSave", FlxSave);
        setGlobalVariable("FlxTimer", FlxTimer);
        setGlobalVariable("FlxSort", FlxSort);
        setGlobalVariable("FlxColor", FlxScriptColor);

        #if (!js || !html5)
        setGlobalVariable("FlxModding", FlxModding);
        #end

        // Tweens
        setGlobalVariable("FlxTween", FlxTween);
        setGlobalVariable("FlxEase", FlxEase);

        // Effects
        setGlobalVariable("FlxFlicker", FlxFlicker);    
    }

    public static function init():Void
    {
        globalVariables = new Map<String, Dynamic>();

        loadFlixelClasses();    
    }

    public static function setGlobalVariable(key:String, value:Dynamic):Void
    {
        globalVariables.set(key, value);
    }

    public static function getGlobalVariable(key:String):Dynamic
    {
        return globalVariables.get(key);
    }
}

#if hscript
private class FlxInterp extends Interp
{
    var origin:String = "FlxHScript";

    public function new(?origin:String)
    {
        super();
        
        #if hscriptPos
        if (origin != null)
            this.origin = origin;
        #end
    }

    override public function posInfos():PosInfos
    {
        #if hscriptPos
		if (curExpr != null)
			return cast { fileName : origin, lineNumber : curExpr.line };
		#end

        return cast { fileName : "FlxHScript", lineNumber : 0 };
    }  
}
#end

private class FlxScriptColor
{
	public static var TRANSPARENT:FlxColor = 0x00000000;
	public static var WHITE:FlxColor = 0xFFFFFFFF;
	public static var GRAY:FlxColor = 0xFF808080;
	public static var BLACK:FlxColor = 0xFF000000;

	public static var GREEN:FlxColor = 0xFF008000;
	public static var LIME:FlxColor = 0xFF00FF00;
	public static var YELLOW:FlxColor = 0xFFFFFF00;
	public static var ORANGE:FlxColor = 0xFFFFA500;
	public static var RED:FlxColor = 0xFFFF0000;
	public static var PURPLE:FlxColor = 0xFF800080;
	public static var BLUE:FlxColor = 0xFF0000FF;
	public static var BROWN:FlxColor = 0xFF8B4513;
	public static var PINK:FlxColor = 0xFFFFC0CB;
	public static var MAGENTA:FlxColor = 0xFFFF00FF;
	public static var CYAN:FlxColor = 0xFF00FFFF;

    public static var colorLookup(default, null):Map<String, Int> = FlxMacroUtil.buildMap("flixel.util.FlxColor");

    static var COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;

    public static function fromInt(Value:Int):FlxColor
	{
		return new FlxColor(Value);
	}

    public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		var color = new FlxColor();
		return color.setRGB(Red, Green, Blue, Alpha);
	}

    public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}

    public static function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

    public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}

	public static function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}

    public static function fromString(str:String):Null<FlxColor>
	{
		var result:Null<FlxColor> = null;
		str = StringTools.trim(str);

		if (COLOR_REGEX.match(str))
		{
			var hexColor:String = "0x" + COLOR_REGEX.matched(2);
			result = new FlxColor(Std.parseInt(hexColor));
			if (hexColor.length == 8)
			{
				result.alphaFloat = 1;
			}
		}
		else
		{
			str = str.toUpperCase();
			for (key in colorLookup.keys())
			{
				if (key.toUpperCase() == str)
				{
					result = new FlxColor(colorLookup.get(key));
					break;
				}
			}
		}

		return result;
	}
}