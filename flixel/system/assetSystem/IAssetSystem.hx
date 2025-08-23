package flixel.system.assetSystem;

import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Future;
#if (flixel >= "5.9.0")
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
#else
import openfl.utils.AssetType;

enum abstract FlxAssetType(String)
{
	var BINARY = "binary";
	var FONT = "font";
	var IMAGE ="image";
	var SOUND = "sound";
	var TEXT = "text";
	
	public function toOpenFlType()
	{
		return switch((cast this:FlxAssetType))
		{
			case BINARY: AssetType.BINARY;
			case FONT: AssetType.FONT;
			case IMAGE: AssetType.IMAGE;
			case SOUND: AssetType.SOUND;
			case TEXT: AssetType.TEXT;
		}
	}
}
#end

interface IAssetSystem
{
	private var bitmaps:Map<String, BitmapData>;
	private var sounds:Map<String, Sound>;
	private var fonts:Map<String, Font>;

    public function getAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>;
    public function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>;
    public function exists(id:String, ?type:FlxAssetType):Bool;

    public function list(?type:FlxAssetType):Array<String>;
    public function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool;

	public function clear():Void;

    public function getText(id:String, useCache:Bool = true):String;
    public function getBytes(id:String, useCache:Bool = true):Bytes;
    public function getBitmapData(id:String, useCache:Bool = true):BitmapData;
    public function getSound(id:String, useCache:Bool = true):Sound;
    public function getFont(id:String, useCache:Bool = true):Font;
}