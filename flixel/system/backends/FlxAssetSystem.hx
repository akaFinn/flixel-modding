package flixel.system.backends;

import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets;
import openfl.utils.Future;
#if (flixel >= "5.9.0")
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
#else
import flixel.system.backends.IAssetSystem.FlxAssetType;
#end

class FlxAssetSystem implements IAssetSystem
{
    public function new()
    {
        clear();
    }

    public function getAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
    {
        if (isOpenFLAsset(id))
            return getOpenFLAsset(id, type, useCache);
        
        var asset:Any = switch type
		{
            case TEXT:
                FlxModding.system.fileSystem.getFileContent(FlxModding.system.sanitize(id));
			case BINARY:
				FlxModding.system.fileSystem.getFileBytes(FlxModding.system.sanitize(id));
			
			case IMAGE if (useCache && Assets.cache.hasBitmapData(FlxModding.system.sanitize(id))):
				Assets.cache.getBitmapData(FlxModding.system.sanitize(id));
			case SOUND if (useCache && Assets.cache.hasSound(FlxModding.system.sanitize(id))):
				Assets.cache.getSound(FlxModding.system.sanitize(id));
			case FONT if (useCache && Assets.cache.hasFont(FlxModding.system.sanitize(id))):
				Assets.cache.getFont(FlxModding.system.sanitize(id));
			
			case IMAGE:
				var bitmap = BitmapData.fromFile(FlxModding.system.sanitize(id));
				if (useCache)
					Assets.cache.setBitmapData(FlxModding.system.sanitize(id), bitmap);
				bitmap;
			case SOUND:
				var sound = Sound.fromFile(FlxModding.system.sanitize(id));
				if (useCache) 
					Assets.cache.setSound(FlxModding.system.sanitize(id), sound);
				sound;
			case FONT:
				var font = Font.fromFile(FlxModding.system.sanitize(id));
				if (useCache)
					Assets.cache.setFont(FlxModding.system.sanitize(id), font);
				font;
		}

        if (type == FONT)
        {
            trace(id, asset);
        }

		return asset;
    }

    public function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>
    {
        return Future.withValue(getAsset(id, type, useCache));
    }

    public function exists(id:String, ?type:FlxAssetType):Bool
    {
        if (isOpenFLAsset(id))
            return Assets.exists(id, type.toOpenFlType());

        return FlxModding.system.fileSystem.exists(FlxModding.system.sanitize(id));
    }

    public function clear():Void
    {
        Assets.cache.clear();
    }

	public function list(?type:FlxAssetType):Array<String>
	{
		var list:Array<String> = [];

		function addFiles(directory:String, prefix = "")
		{
			for (path in FlxModding.system.fileSystem.readFolder(directory))
			{
				if (FlxModding.system.fileSystem.isFolder(directory + "/" + path))
					addFiles(directory + "/" + path, prefix + path + "/");
				else
					list.push(FlxModding.system.sanitize(prefix + path));
			}
		}

		@:privateAccess
        addFiles(FlxModding.assetDirectory);
		return list;
	}

    public function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool
    {
        if (isOpenFLAsset(id) && useCache)
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

    function isOpenFLAsset(id:String):Bool
    {
        @:privateAccess
        return StringTools.startsWith(id, FlxModding.flixelDirectory) || StringTools.contains(id, ":");
    }

    function getOpenFLAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
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