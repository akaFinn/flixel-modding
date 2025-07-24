package flixel.system;

import flixel.FlxG;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.system.debug.log.LogStyle;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.Future;

#if (!js || !html5)
import sys.FileSystem;
import sys.io.File;
#end

typedef CreditFormat = 
{
    var name:String;
    var title:String;
    var socials:String;
}

typedef MetadataFormat = 
{
    var name:String;
    var version:String;
    var description:String;

    var credits:Array<CreditFormat>;

    var priority:Int;
    var active:Bool;
}

/**
 * Central utility class for handling mod-related operations in the Flixel-Modding framework.
 * 
 * The `FlxModding` class provides a collection of static methods for managing the full 
 * lifecycle of mods—this includes initializing mod systems at startup, dynamically 
 * reloading mod content during runtime, and assisting with the creation or registration 
 * of new modpacks.
 * 
 * All interaction between the core engine and external mods should be routed through this class 
 * to maintain consistency and modularity. It serves as the main bridge between user-created 
 * modpacks and the game engine, offering a streamlined API for developers to plug into.
 * 
 * Common uses include loading mod metadata, accessing registered modpacks, refreshing assets, 
 * and toggling caching behaviors for more efficient memory management.
 */
class FlxModding
{
	// ===============================
	// Public API
	// ===============================

	/**
	 * The Base Flixel-Modding version, in semantic versioning syntax.
	 */
	public static var VERSION:FlxVersion = new FlxVersion(1, 2, 0);

	/**
	 * Use this to toggle Flixel-Modding between on and off.
	 * You can easily toggle this with e.g.: `FlxModding.enabled = !FlxModding.enabled;`
	 */
	public static var enabled:Bool;

	/**
	 * Use this to enable or disable caching for assets.
	 * When caching is enabled, assets will be stored in memory after loading,
	 * which can improve performance when accessing the same assets multiple times.
	 */
	public static var caching:Bool;

	/**
	 * Used for grabbing, loading, or listing assets.
	 * Acts as an alternative to `FlxG.assets`, with support for modded assets.
	 */
	public static var system:FlxModding;

	/**
	 * The container for every single mod available for Flixel-Modding.
	 * All mods are listed here, whether active or not.
	 */
	public static var mods:FlxTypedContainer<FlxModpack>;

	// ===============================
	// Lifecycle Signals
	// ===============================

	/**
	 * Signal fired before modpacks are reloaded.
	 * Useful for saving state or cleaning up.
	 */
	public static var preModsReload:FlxSignal = new FlxSignal();

	/**
	 * Signal fired after modpacks are reloaded.
	 * Can be used to refresh UI or data.
	 */
	public static var postModsReload:FlxSignal = new FlxSignal();

	/**
	 * Signal fired before modpacks update.
	 * Great for prep work or modifying metadata.
	 */
	public static var preModsUpdate:FlxSignal = new FlxSignal();

	/**
	 * Signal fired after modpacks update.
	 * Use this to apply changes or react to updates.
	 */
	public static var postModsUpdate:FlxSignal = new FlxSignal();

	/**
	 * Fires when a new modpack is added.
	 * Can be used to initialize systems or load mod-specific content.
	 * Passes the added FlxModpack.
	 */
	public static var onModAdded:FlxTypedSignal<FlxModpack->Void> = new FlxTypedSignal<FlxModpack->Void>();

	/**
	 * Fires when a modpack is removed from the system.
	 * Useful for cleaning up resources tied to that mod.
	 * Passes the removed FlxModpack.
	 */
	public static var onModRemoved:FlxTypedSignal<FlxModpack->Void> = new FlxTypedSignal<FlxModpack->Void>();

	// ===============================
	// Private Internals
	// ===============================

	static var assetDirectory:String = "assets";
	static var modsDirectory:String = "mods";

	static var metaDirectory:String = "metadata.json";
	static var iconDirectory:String = "picture.png";

	// NOTE: polymod rocks. These are remnants from when I started polymod support.
	// Might expand this in a future update.
    // Love u eric <3<3<3.
	static var metaPolymodDirectory:String = "_polymod_meta.json";
	static var iconPolymodDirectory:String = "_polymod_icon.png";

    /**
     * Initializes Flixel-Modding to enable support for loading and reloading modded assets at runtime.
     * This function sets up internal directories and flags needed to ensure mods function correctly,
     * including file presence checks and signal hookups for automatic reloads on game reset.
     * 
     * It is highly recommended that you call this method BEFORE instantiating `new FlxGame();`
     * or performing any asset-related operations to avoid misconfiguration issues.
     * 
     * This setup is only available on native targets (like Windows, Mac, or Linux). 
     * It will not function in JS/HTML5 builds due to file system access restrictions.
     * 
     * @param   allowCaching  (Optional) A toggle for caching game assets
     * 
     * @param   assetDirectory  (Optional) A path that overrides the default directory for game assets. 
     *                          Use this if your mod uses a custom asset folder structure.
     * 
     * @param   modsDirectory   (Optional) A path that overrides the default directory used to store mods.
     *                          This folder is where all mods and associated data should reside.
     * 
     * @return                  The initialized FlxModding system so it can be assigned or used directly.
     */
    public static function init(?allowCaching:Bool = true, ?assetDirectory:String, ?modsDirectory:String):FlxModding
    {   
        #if (!js || !html5)
        FlxG.log.add("Attempting to Initialize FlxModding...");
        if (assetDirectory != null) flixel.system.FlxModding.assetDirectory = assetDirectory;
        if (modsDirectory != null) flixel.system.FlxModding.modsDirectory = modsDirectory;

        if (FileSystem.exists(FlxModding.modsDirectory + "/"))
        {
            if (!FileSystem.exists(FlxModding.modsDirectory + "/" + FlxModding.modsDirectory + "-go-here.txt"))
            {
                File.saveContent(FlxModding.modsDirectory + "/" + FlxModding.modsDirectory + "-go-here.txt", "");
            }
            
            enabled = true;
            caching = allowCaching;
            system = new FlxModding();
            mods = new FlxTypedContainer<FlxModpack>();
        
            #if (flixel >= "3.3.0")
            FlxG.signals.preGameReset.add(function ()
            {
                FlxModding.reload();
            });
            #end

            FlxG.log.add("FlxModding Initialized!");
            return system;
        }
        else
        {
            FlxG.log.error("Critical Error! " + FlxModding.modsDirectory + " not found. Please ensure that the directory exists on your filesystem and that it has been properly declared in your 'Project.xml' file. Without this, Flixel-Modding will fail to operate as expected.");
            FlxG.stage.window.alert(FlxModding.modsDirectory + " not found. Please ensure that the directory exists on your filesystem and that it has been properly declared in your 'Project.xml' file. Without this, Flixel-Modding will fail to operate as expected.", "Critical Error!");
            FlxG.stage.window.close();
            return null;
        }

        #else
        FlxG.log.error("Critical Error! Cannot access required filesystem functionality when targeting JavaScript or HTML5. Native targets are required for modding support.");
        FlxG.stage.window.alert("Cannot access required filesystem functionality when targeting JavaScript or HTML5. Native targets are required for modding support.", "Critical Error!");
        FlxG.stage.window.close();
        return null;
        #end
    }

    /**
     * Reloads all modpacks found in the mods directory and populates them into `FlxModding.mods`.
     * This is automatically triggered during game reset events to ensure all mod data is refreshed.
     * 
     * Useful for reinitializing modpacks without restarting the entire application.
     * 
     * @param   updateMetadata  (Optional) Choose whether to save modpack data to the metadata file.
     */
    public static function reload(?updateMetadata:Bool = true):Void
    {
        #if (!js || !html5)
        preModsReload.dispatch();
        FlxG.log.add("Attempting to Reload modpacks...");

        if (updateMetadata == true && mods.length != 0)
        {
            if (enabled)
            {
                FlxModding.update();
            }
        }

        mods.clear();

        for (modFile in FileSystem.readDirectory(FlxModding.modsDirectory + "/"))
        {
            if (FileSystem.isDirectory(FlxModding.modsDirectory + "/" + modFile) && enabled)
            {
                var modpack = new FlxModpack(modFile);

                if (system.exists(FlxModding.modsDirectory + "/" + modpack.file + "/" + metaDirectory))
                {
                    var metadata:MetadataFormat = Json.parse(system.getAsset(FlxModding.modsDirectory + "/" + modFile + "/" + FlxModding.metaDirectory, TEXT, false));

                    modpack.name = metadata.name;
                    modpack.version = metadata.version;
                    modpack.description = metadata.description;

                    modpack.credits = metadata.credits;

                    modpack.active = metadata.active;
                    modpack.priority = metadata.priority;
                }
                else
                {
                    FlxG.log.warn("Failed to locate Metadata, file does not exist. Using fallback/default values instead.");

                    modpack.name = modFile;
                    modpack.version = "1.0.0";
                    modpack.description = "";

                    modpack.credits = [];

                    modpack.active = true;
                    modpack.priority = -1;
                }

                add(modpack);
            }
        }

        FlxG.log.add("Modpacks Reloaded!");
        postModsReload.dispatch();

        mods.sort((order, mod1, mod2) ->
        {
            return FlxSort.byValues(order, mod1.priority, mod2.priority);
        });
        #else
        FlxG.log.error("Critical Error! Cannot reload mods while targeting JavaScript or HTML5");
        FlxG.stage.window.alert("Cannot reload mods while targeting JavaScript or HTML5", "Critical Error!");
        FlxG.stage.window.close();
        #end
    }

    /**
     * Iterates through all registered modpacks and updates their metadata.
     * This function is typically used to refresh mod-related information 
     * such as name, version, description, or any other data stored within 
     * the modpack's metadata. Should be called when modpack contents 
     * change or need to be re-synced with their internal data.
     * 
     * @param   modpack  (Optional) The modpack you that will update when it isn't null
     */
    public static function update(?modpack:FlxModpack):Void
    {
        preModsUpdate.dispatch();

        if (modpack != null)
        {
            modpack.updateMetadata();
        }
        else
        {
            for (otherModpack in mods)
            {
                otherModpack.updateMetadata();
            }
        }

        postModsUpdate.dispatch();
    }

    /**
     * Creates a new modpack using the provided metadata and options.
     * Automatically places the generated modpack inside the active mods directory.
     * 
     * @param   metadata           Contains modpack information such as the name and structure. 
     *                             If you're using a custom-named assets folder, this helps define it.
     * 
     * @param   makeAssetFolders   If true, automatically generates empty asset subfolders within the modpack.
     *                             Useful when you want to scaffold common asset paths.
     */
    public static function create(fileName:String, iconBitmap:BitmapData, metadata:MetadataFormat, ?makeAssetFolders:Bool = true):Void
    {
        #if (!js || !html5)
        FlxG.log.add("Attempting to Create a modpack...");
        if (!FileSystem.exists(FlxModding.modsDirectory + "/" + fileName))
        {
            FileSystem.createDirectory(FlxModding.modsDirectory + "/" + fileName);
            File.saveContent(FlxModding.modsDirectory + "/" + fileName + "/" + FlxModding.metaDirectory, convertToString(metadata));

            var encodedBytes = iconBitmap.encode(iconBitmap.rect, new PNGEncoderOptions());
            var iconData = Bytes.alloc(encodedBytes.length);
            encodedBytes.position = 0;
            encodedBytes.readBytes(iconData, 0, encodedBytes.length);

            File.saveBytes(FlxModding.modsDirectory + "/" + fileName + "/" + FlxModding.iconDirectory, iconData);

            if (makeAssetFolders == true)
            {
                for (asset in FileSystem.readDirectory(FlxModding.assetDirectory))
                {
                    FileSystem.createDirectory(FlxModding.modsDirectory + "/" + fileName + "/" + asset);
                    File.saveContent(FlxModding.modsDirectory + "/" + fileName + "/" + asset + "/content-goes-here.txt", "");
                }
            }

            FlxG.log.add("Modpack Created!");
        }
        else
        {
            FlxG.log.warn("The mod: " + fileName + " has already been created. You cannot create a mod with the same name.");
        }
        #end
    }

    /**
     * Adds a modpack to the current list of loaded mods.
     * Useful when dynamically inserting modpacks after initialization.
     * 
     * @param   modpack   The modpack instance to be added to the container.
     */
    public static function add(modpack:FlxModpack):Void
    {
        onModAdded.dispatch(modpack);
        mods.add(modpack);
    }

    /**
     * Removes a modpack from the current list of loaded mods.
     * Call this if you need to disable or unload a mod at runtime.
     * 
     * @param   modpack   The modpack instance to remove from the container.
     */
    public static function remove(modpack:FlxModpack):Void
    {
        onModRemoved.dispatch(modpack);
        mods.remove(modpack);
    }

    /**
     * Attempts to find and return a modpack by its name.
     * The search is case-insensitive.
     * 
     * @param   name   The name of the modpack to look for.
     * 
     * @return         The matching modpack, or null if not found.
     */
    public static function get(name:String):FlxModpack
    {
        for (modpack in mods.members)
        {
            if (modpack.name.toLowerCase() == name.toLowerCase())
            {
                return modpack;
            }
        }

        FlxG.log.warn("Failed to locate Modpack: " + name + ", are you sure you spelt the name correctly?");
        return null;
    }
    
    public function new()
    {
        #if (!js || !html5)
        #if (flixel >= "5.9.0")
        FlxG.assets.getAssetUnsafe = this.getAsset;
        FlxG.assets.loadAsset = this.loadAsset;
        FlxG.assets.exists = this.exists;

        FlxG.assets.list = this.list;
        FlxG.assets.isLocal = this.isLocal;
        #else
        FlxG.log.error("Critical Error! Cannot run the FlxModding instance, HaxeFlixel is OUT OF DATE. Please update to HaxeFlixel version 5.9.0 or higher");
        FlxG.stage.window.alert("Cannot run the FlxModding instance, HaxeFlixel is OUT OF DATE. Please update to HaxeFlixel version 5.9.0 or higher", "Critical Error!");
        FlxG.stage.window.close();
        #end
        #end
    }

    public function getAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache:Bool = true):Null<Any>
    {
        #if (!js || !html5)
        /*trace("Attempting to grab Asset");
        trace(id, "is flixel asset: " + StringTools.startsWith(id, "flixel/"));*/

        if (StringTools.startsWith(id, "flixel/"))
            return getOpenFLAsset(id, type, useCache);

        //trace("-----");

        var allowCache = useCache && caching;
        var asset:Any = switch type
		{
            case TEXT:
                File.getContent(redirect(id));
			case BINARY:
				File.getBytes(redirect(id));
			
			case IMAGE if ((OpenFLAssets.cache.enabled && allowCache) && OpenFLAssets.cache.hasBitmapData(redirect(id))):
				OpenFLAssets.cache.getBitmapData(redirect(id));
			case SOUND if ((OpenFLAssets.cache.enabled && allowCache) && OpenFLAssets.cache.hasSound(redirect(id))):
				OpenFLAssets.cache.getSound(redirect(id));
			case FONT if ((OpenFLAssets.cache.enabled && allowCache) && OpenFLAssets.cache.hasFont(redirect(id))):
				OpenFLAssets.cache.getFont(redirect(id));
			
			case IMAGE:
				var bitmap = BitmapData.fromFile(redirect(id));
				if (OpenFLAssets.cache.enabled && allowCache)
					OpenFLAssets.cache.setBitmapData(redirect(id), bitmap);
				bitmap;
			case SOUND:
				var sound = Sound.fromFile(redirect(id));
				if (OpenFLAssets.cache.enabled && allowCache) 
					OpenFLAssets.cache.setSound(redirect(id), sound);
				sound;
			case FONT:
				var font = Font.fromFile(redirect(id));
				if (OpenFLAssets.cache.enabled && allowCache)
					OpenFLAssets.cache.setFont(redirect(id), font);
				font;
		}
		
		return asset;
        #else
        return getOpenFLAsset(id, type, useCache);
        #end
    }

    public function loadAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache:Bool = true):Future<Any>
    {
        return Future.withValue(getAsset(id, type, useCache));
    }

    public function exists(id:String, ?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType):Bool
    {
        #if (!js || !html5)
        if (StringTools.startsWith(id, "flixel/"))
            return OpenFLAssets.exists(id);

        return FileSystem.exists(redirect(id));
        #end
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

		addFiles(FlxModding.assetDirectory, Path.withoutDirectory(FlxModding.assetDirectory) + "/");
        addFiles(FlxModding.modsDirectory, Path.withoutDirectory(FlxModding.modsDirectory) + "/");

		return list;
        #else
        return OpenFLAssets.list(type.toOpenFlType());
        #end
    }

    public function isLocal(id:String, ?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache:Bool = true)
    {
        var allowCache = useCache && caching;

        if (StringTools.startsWith(id, "flixel/"))
			OpenFLAssets.isLocal(id, type.toOpenFlType(), allowCache);

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

    function getOpenFLAsset(id:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, useCache:Bool = true):Null<Any>
	{
		return switch(type)
		{
			case TEXT: OpenFLAssets.getText(id);
			case BINARY: OpenFLAssets.getBytes(id);
			case IMAGE: OpenFLAssets.getBitmapData(id, useCache);
			case SOUND: OpenFLAssets.getSound(id, useCache);
			case FONT: OpenFLAssets.getFont(id, useCache);
		}
	}

    /**
     * Redirects an asset path to the appropriate mod or asset directory.
     */
    function redirect(id:String):String
    {
        mods.sort((order, mod1, mod2) ->
        {
            return FlxSort.byValues(order, mod1.priority, mod2.priority);
        });

        if (StringTools.startsWith(id, "flixel/") || StringTools.startsWith(id, FlxModding.modsDirectory + "/"))
        {
            return id;
        }
        else if (StringTools.startsWith(id, FlxModding.assetDirectory + "/"))
        {
            return pathway(id.substr(Std.string(FlxModding.assetDirectory + "/").length));
        }
        else
        {
            return pathway(id);
        }
    }

    /**
     * Resolves the correct file path for a given asset ID, checking active mods first.
     */
    function pathway(id:String):String
    {
        #if (!js || !html5)
        var directory = FlxModding.assetDirectory;

        for (modpack in mods)
        {
            if ((modpack.active && modpack.alive && modpack.exists) && enabled && FileSystem.exists(FlxModding.modsDirectory + "/" + modpack.file + "/" + id))
            {
                directory = FlxModding.modsDirectory + "/" + modpack.file;
            }
        }

        return directory + "/" + id;
        #end
        
        return null;
    }

    // This right here is the worst fucking code I've ever made, nearly killed myself figuring out how to write this.
    // And omfg the old version was so much worse
    static function convertToString(metadata:MetadataFormat):String
    {
        var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"name": "' + metadata.name + '",\n');
        buf.add('\t"version": "' + metadata.version + '",\n');
        buf.add('\t"description": "' + metadata.description + '",\n');
        buf.add('\n\t"credits": [\n');

        for (index in 0...metadata.credits.length) 
        {
            var credit = metadata.credits[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + credit.name + '",\n');
            buf.add('\t\t\t"title": "' + credit.title + '",\n');
            buf.add('\t\t\t"socials": "' + credit.socials + '"\n');
            buf.add('\t\t}');

            if (index < metadata.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"priority": ' + metadata.priority + ',\n');
        buf.add('\t"active": ' + metadata.active + '\n');
        buf.add('}');

        return buf.toString();
    }
}