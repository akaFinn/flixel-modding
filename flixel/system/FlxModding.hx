package flixel.system;

import flixel.FlxG;
import haxe.Json;
import haxe.io.Path;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets;
import openfl.utils.Future;

#if (!js || !html5)
import sys.FileSystem;
import sys.io.File;
#end

#if (flixel >= "5.9.0")
class FlxModding
{
    public static var VERSION:String = "1.1.0";

    static var assetDirectory:String = "assets";
    static var modsDirectory:String = "mods";

    static var metaDirectory:String = ".mod_meta";

    public static var enabled:Bool = true;
    public static var system:FlxModding;
    public static var mods:Array<FlxModpack>;

    public static function init(?assetDirectory:String, ?modsDirectory:String):Void
    {   
        #if (!js || !html5)
        if (assetDirectory != null) flixel.system.FlxModding.assetDirectory = assetDirectory;
        if (modsDirectory != null) flixel.system.FlxModding.modsDirectory = modsDirectory;
        
        system = new FlxModding();
        FlxModding.reload();

        FlxG.signals.preGameReset.add(function ()
        {
            FlxModding.reload();
        });
        #else
        FlxG.log.error("Critical Error! Cannot access core packages while targeting js.");
        #end
    }

    public static function reload():Void
    {
        #if (!js || !html5)
        mods = [];

        for (modFile in FileSystem.readDirectory(FlxModding.modsDirectory + "/"))
        {
            if (FileSystem.isDirectory(FlxModding.modsDirectory + "/" + modFile) && enabled)
            {
                var modpack = new FlxModpack(modFile);
                add(modpack);

                if (system.exists(modpack.formDirectory() + "/" + metaDirectory))
                {
                    var metadata = Json.parse(system.getAsset(FlxModding.modsDirectory + "/" + modFile + "/" + FlxModding.metaDirectory, TEXT, false));

                    modpack.name = metadata.name;
                    modpack.author = metadata.author;
                    modpack.description = metadata.description;
                    modpack.active = metadata.active;
                    modpack.priority = metadata.priority;
                }
                else
                {
                    FlxG.log.warn("Failed to locate Metadata, file does not exists and cannot access data such as the name of the modpack nor the priority.");

                    modpack.name = modFile;
                    modpack.author = "Unknown";
                    modpack.active = true;
                    modpack.priority = -1;
                }
            }
        }

        mods.sort(function(a, b) return Reflect.compare(a.priority, b.priority));
        #end
    }

    public static function create(modName:String, ?makeAssetFolders:Bool = true):Void
    {
        #if (!js || !html5)
        if (!FileSystem.exists(FlxModding.modsDirectory + "/" + modName))
        {
            FileSystem.createDirectory(FlxModding.modsDirectory + "/" + modName);
            File.saveContent(FlxModding.modsDirectory + "/" + modName + "/" + FlxModding.metaDirectory,
'{
    "name":"New Mod",
    "author":"Unknown",
    "description":"",
    "active":false,
    "priority":1
}');

            if (makeAssetFolders == true)
            {
                for (asset in FileSystem.readDirectory(FlxModding.assetDirectory))
                {
                    FileSystem.createDirectory(FlxModding.modsDirectory + "/" + modName + "/" + asset);
                    File.saveContent(FlxModding.modsDirectory + "/" + modName + "/" + asset + "/content-goes-here.txt", "");
                }
            }
        }
        else
        {
            FlxG.log.warn("The mod: " + modName + " has already been create. You cannot create a mod with the same name.");
        }
        #end
    }

    public static function add(modpack:FlxModpack):Void
    {
        mods.push(modpack);
    }

    public static function remove(modpack:FlxModpack):Void
    {
        mods.remove(modpack);
    }
    
    public function new(?mergeAssetCollection:Bool = true)
    {
        if (mergeAssetCollection == true)
        {
            FlxG.assets.getAssetUnsafe = this.getAsset;
            FlxG.assets.loadAsset = this.loadAsset;
            FlxG.assets.exists = this.exists;

            FlxG.assets.list = this.list;
            FlxG.assets.isLocal = this.isLocal;
        }
    }

    public function getAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache = true):Null<Any>
    {
        #if (!js || !html5)
        if (useOpenflAssets(id))
            getOpenflAsset(id, type, useCache);

        var asset:Any = switch type
		{
			case TEXT:
				File.getContent(redirect(id));
			case BINARY:
				File.getBytes(redirect(id));
			
			case IMAGE if ((Assets.cache.enabled && useCache) && Assets.cache.hasBitmapData(id)):
				Assets.cache.getBitmapData(id);
			case SOUND if ((Assets.cache.enabled && useCache) && Assets.cache.hasSound(id)):
				Assets.cache.getSound(id);
			case FONT if ((Assets.cache.enabled && useCache) && Assets.cache.hasFont(id)):
				Assets.cache.getFont(id);
			
			case IMAGE:
				var bitmap = BitmapData.fromFile(redirect(id));
				if (Assets.cache.enabled && useCache)
					Assets.cache.setBitmapData(id, bitmap);
				bitmap;
			case SOUND:
				var sound = Sound.fromFile(redirect(id));
				if (Assets.cache.enabled && useCache)
					Assets.cache.setSound(id, sound);
				sound;
			case FONT:
				var font = Font.fromFile(redirect(id));
				if (Assets.cache.enabled && useCache)
					Assets.cache.setFont(id, font);
				font;
		}
		
		return asset;
        #end
        
        return null;
    }

    public function loadAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache = true):Future<Any>
    {
        return Future.withValue(getAsset(id, type, useCache));
    }

    public function exists(id:String, ?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType):Bool
    {
        if (useOpenflAssets(id))
            Assets.exists(id);

        #if (!js || !html5)
        return FileSystem.exists(redirect(id));
        #end

        return false;
    }

    public function list(?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType):Array<String>
    {
        #if (!js || !html5)
        var list = [];
		function addFiles(directory:String, prefix = "")
		{
			for (path in FileSystem.readDirectory(directory))
			{
				if (FileSystem.isDirectory('$directory/$path'))
					addFiles('$directory/$path', prefix + path + '/');
				else
					list.push(prefix + path);
			}
		}

		var assetPrefix = Path.withoutDirectory(FlxModding.assetDirectory) + "/";
		addFiles(FlxModding.assetDirectory, assetPrefix);

        var modPrefix = Path.withoutDirectory(FlxModding.modsDirectory) + "/";
        addFiles(FlxModding.modsDirectory, modPrefix);

		return list;
        #end
        
        return null;
    }

    public function isLocal(id:String, ?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache = true)
    {
        if (useOpenflAssets(id))
			Assets.isLocal(id, type.toOpenFlType(), useCache);

        return true;
    }

    function useOpenflAssets(id:String)
	{
		return StringTools.startsWith(id, "flixel/");
	}

    function getOpenflAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache = true):Null<Any>
	{
		return switch(type)
		{
			case TEXT: Assets.getText(id);
			case BINARY: Assets.getBytes(id);
			case IMAGE: Assets.getBitmapData(id, useCache);
			case SOUND: Assets.getSound(id, useCache);
			case FONT: Assets.getFont(id, useCache);
		}
	}

    function redirect(id:String):String
    {
        mods.sort(function(a, b) return Reflect.compare(a.priority, b.priority));

        if (StringTools.startsWith(id, "flixel/") || StringTools.startsWith(id, FlxModding.modsDirectory + "/"))
        {
            return id;
        }
        else if (StringTools.startsWith(id, FlxModding.assetDirectory + "/"))
        {
            return pathway(id.substr(Std.string(FlxModding.assetDirectory + "/").length));
        }
        /*else if (StringTools.startsWith(id, FlxModding.modsDirectory + "/"))
        {
            return pathway(id.substr(Std.string(FlxModding.modsDirectory + "/" + id.split("/")[1] + "/").length));
        }*/
        else
        {
            return pathway(id);
        }
    }

    function pathway(id:String):String
    {
        #if (!js || !html5)
        var directory = FlxModding.assetDirectory;

        for (modpack in mods)
        {
            if (modpack.active && FileSystem.exists(modpack.formDirectory() + "/" + id) && enabled)
            {
                directory = modpack.formDirectory();
            }
        }

        return directory + "/" + id;
        #end
        
        return null;
    }
}
#else
class FlxModding
{
    public static function init(?assetDirectory:String, ?modsDirectory:String):Void
    {
        FlxG.log.error("Critical Error! HaxeFlixel is out of date, flixel-modding does not support HaxeFlixel for version 5.8.0 or under, please update to version 5.9.0 or higher.");   
    }
}
#end