package flixel.system.assetSystem;

import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets;
import openfl.utils.Future;
#if (flixel >= "5.9.0")
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
#else
import flixel.system.assetSystem.IAssetSystem.FlxAssetType;
#end

class FlxAssetSystem implements IAssetSystem
{
	private var bitmaps:Map<String, BitmapData>;
	private var sounds:Map<String, Sound>;
	private var fonts:Map<String, Font>;

	public function new()
	{
		lime.utils.Assets.cache.enabled = false;
		openfl.utils.Assets.cache.enabled = false;

		bitmaps = new Map<String, BitmapData>();
		sounds = new Map<String, Sound>();
		fonts = new Map<String, Font>();
		clear();
	}

	public function getAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
	{
		if (isFlixelAsset(id))
			return getFlixelAsset(id, type, useCache);

		var asset:Any = switch type
		{
			case TEXT:
				FlxModding.system.fileSystem.getFileContent(FlxModding.system.sanitize(id));
			case BINARY:
				FlxModding.system.fileSystem.getFileBytes(FlxModding.system.sanitize(id));

			case IMAGE if (useCache && bitmaps.exists(FlxModding.system.sanitize(id))):
				bitmaps.get(FlxModding.system.sanitize(id));
			case SOUND if (useCache && sounds.exists(FlxModding.system.sanitize(id))):
				sounds.get(FlxModding.system.sanitize(id));
			case FONT if (useCache && fonts.exists(FlxModding.system.sanitize(id))):
				fonts.get(FlxModding.system.sanitize(id));

			case IMAGE:
				var bitmap = BitmapData.fromFile(FlxModding.system.sanitize(id));
				if (useCache)
					bitmaps.set(FlxModding.system.sanitize(id), bitmap);
				bitmap;
			case SOUND:
				var sound = Sound.fromFile(FlxModding.system.sanitize(id));
				if (useCache)
					sounds.set(FlxModding.system.sanitize(id), sound);
				sound;
			case FONT:
				var font = Font.fromFile(FlxModding.system.sanitize(id));
				if (useCache)
					fonts.set(FlxModding.system.sanitize(id), font);
				font;
		}

		return asset;
	}

	public function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>
	{
		return Future.withValue(getAsset(id, type, useCache));
	}

	public function exists(id:String, ?type:FlxAssetType):Bool
	{
		if (isFlixelAsset(id))
			return Assets.exists(id, type.toOpenFlType());

		return FlxModding.system.fileSystem.exists(FlxModding.system.sanitize(id));
	}

	public function clear():Void
	{
		bitmaps.clear();
		sounds.clear();
		fonts.clear();

		lime.utils.Assets.cache.clear();
		openfl.utils.Assets.cache.clear();
	}

	public function list(?type:FlxAssetType):Array<String>
	{
		var list = [];
		function addFiles(directory:String, prefix = "")
		{
			for (path in FlxModding.system.fileSystem.readFolder(directory))
			{
				if (FlxModding.system.fileSystem.isFolder('$directory/$path'))
					addFiles('$directory/$path', prefix + path + '/');
				else
					list.push(prefix + path);
			}
		}

		@:privateAccess
		{
			addFiles(FlxModding.assetDirectory, FlxModding.assetDirectory + "/");
			addFiles(FlxModding.modsDirectory, FlxModding.modsDirectory + "/");
		}

		return list;
	}

	public function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool
	{
		if (isFlixelAsset(id) && useCache)
			return Assets.isLocal(id, type.toOpenFlType());

		return true;
	}

	public function getText(id:String, useCache:Bool = true):String
	{
		return getAsset(id, TEXT, useCache);
	}

	public function getBytes(id:String, useCache:Bool = true):Bytes
	{
		return getAsset(id, BINARY, useCache);
	}

	public function getBitmapData(id:String, useCache:Bool = true):BitmapData
	{
		return getAsset(id, IMAGE, useCache);
	}

	public function getSound(id:String, useCache:Bool = true):Sound
	{
		return getAsset(id, SOUND, useCache);
	}

	public function getFont(id:String, useCache:Bool = true):Font
	{
		return getAsset(id, FONT, useCache);
	}

	function isFlixelAsset(id:String):Bool
	{
		@:privateAccess
		return StringTools.startsWith(id, FlxModding.flixelDirectory);
	}

	function getFlixelAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
	{
		return switch (type)
		{
			case TEXT: Assets.getText(id);
			case BINARY: Assets.getBytes(id);
			case IMAGE: Assets.getBitmapData(id, useCache);
			case SOUND: Assets.getSound(id, useCache);
			case FONT: Assets.getFont(id, useCache);
		}
	}
}
