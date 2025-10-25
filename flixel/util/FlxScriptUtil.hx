package flixel.util;

#if hscript
import flixel.system.hscript.FlxScriptable;
import flixel.system.hscript.FlxScriptableClass;
import hscript.Interp;
import hscript.Parser;

/**
 * @since 1.5.0
 */
class FlxScriptUtil
{
    /**
	 * File extension for basic Script files
	 */	
    public static var SCRIPT_FILE_EXTS:Array<String> = ["hxs"];

    /**
	 * File extension for Scripted Classes
	 */	
    public static var CLASS_FILE_EXTS:Array<String> = ["hxc"];

	/**
	 * File extension for Haxe files
	 */	
    public static var HAXE_FILE_EXTS:Array<String> = ["hx"];

    /**
	 * Default prefix used for identifying scripted classes that want to replace the source code
	 */	
    public static inline var DEFAULT_SOURCE_PREFIX:String = "_source";

    private static var interp:Interp = FlxScriptUtil.buildInterp();

    public static function buildScript(content:String):Void
    {
        var parser:Parser = FlxScriptUtil.buildParser();
        interp.execute(parser.parseString(content));
    }

    static function buildParser():Parser
    {
        var parser:Parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;

        return parser;
    }

    static function buildInterp():Interp
    {
        var interp:Interp = new Interp();
		interp.variables.set("Std", Std);
		interp.variables.set("Math", Math);

        return interp;
    }
}

/*private class FlxScriptedColor
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
}*/
#end