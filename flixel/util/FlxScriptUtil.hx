package flixel.util;

import flixel.sound.FlxSound;
import flixel.system.FlxModding;
import flixel.system.macros.FlxMacroUtil;
import flixel.text.FlxText;
import rulescript.types.Typedefs;

#if hscript
import hscript.Interp;
import hscript.Parser;

#if rulescript
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass.Access;
import rulescript.types.ScriptedTypeUtil;
#end

#if polymod
import polymod.hscript._internal.PolymodScriptClass;
#end

private class FlxScriptedSprite extends FlxSprite implements rulescript.scriptedClass.RuleScriptedClass {}

/**
 * @since 1.5.0
 */
class FlxScriptUtil
{
    private static var defaultGlobalClasses:Array<FlxGlobalClass> =
    [
        {
            name: "FlxSprite",
            cls: FlxSprite,
        },

        {
            name: "FlxG",
            cls: FlxG,
        },

        {
            name: "FlxState",
            cls: FlxState,
        },

        {
            name: "FlxModding",
            cls: FlxModding,
        },

        {
            name: "FlxColor",
            cls: FlxScriptedColor,
        },

        {
            name: "FlxText",
            cls: FlxText,
        },

        {
            name: "FlxObject",
            cls: FlxObject,
        },

        {
            name: "FlxBasic",
            cls: FlxBasic,
        },

        {
            name: "FlxSound",
            cls: FlxSound,
        }
    ];

    public static function buildHScript(code:String):Interp
    {
        var parser:Parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;
        var interp:Interp = new Interp();

        for (globalClass in defaultGlobalClasses)
            interp.variables.set(globalClass.name, globalClass.cls);

        interp.execute(parser.parseString(code));
        return interp;
    }

    #if polymod
    public static function buildPolymodScript(code:String):Void
    {
        @:privateAccess
        PolymodScriptClass.registerScriptClassByString(code);
    }
    #end

    #if rulescript
    public static function buildRuleScript(code:String):Access
    {
        ScriptedTypeUtil.resolveModule = (name:String) -> 
        {
            var path = StringTools.replace(name, ".", "/");

            var parser = new HxParser();
            parser.allowAll();
            parser.mode = MODULE;

            return parser.parseModule(FlxModding.system.fileSystem.getFileContent(path + ".rhx"));
        }

        Typedefs.register("flixel.FlxSprite", FlxScriptedSprite);

        var script = new Access(ScriptedTypeUtil.resolveScript("assets.data.RuleScriptTest"));
        script.doThing();
        return script;
    }
    #end
}
#end

typedef FlxGlobalClass = 
{
    var name:String;
    var cls:Class<Dynamic>;
}

private class FlxScriptedColor
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