package flixel.system;

import flixel.FlxG;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
import flixel.system.scripting.FlxHScript;
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
	public static var VERSION:FlxVersion = new FlxVersion(1, 3, 0);

	/**
	 * Use this to toggle Flixel-Modding between on and off.
	 * You can easily toggle this with e.g.: `FlxModding.enabled = !FlxModding.enabled;`
	 */
	public static var enabled:Bool;

	/**
	 * The asset cache used by Flixel-Modding.
	 * Stores loaded assets in memory so they can be reused without reloading.
	 * Improves performance when accessing assets multiple times.
	 */
	public static var cache:FlxCache;

	/**
	 * Used for grabbing, loading, or listing assets.
	 * Acts as an alternative to `FlxG.assets`, with support for modded assets.
	 */
	public static var system:FlxModding;

    /**
	 * Use this to toggle Flixel-Modding's debug print on or off'
	 */
	public static var debug:Bool = #if debug true #else false #end;

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
	// Private Internals ( ͡° ͜ʖ ͡°)
	// ===============================

	static var assetDirectory:String = "assets";
	static var modsDirectory:String = "mods";

	static var metaDirectory:String = "metadata.json";
	static var iconDirectory:String = "picture.png";

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
     * @param   allowCaching    (Optional) A toggle for caching game assets
     * 
     * @param   assetDirectory  (Optional) A path that overrides the default directory for game assets. 
     *                          Use this if your mod uses a custom asset folder structure.
     * 
     * @param   modsDirectory   (Optional) A path that overrides the default directory used to store mods.
     *                          This folder is where all mods and associated data should reside.
     * 
     * @return                  The initialized FlxModding system so it can be assigned or used directly.
     */
    public static function init(allowCaching:Bool = true, ?assetDirectory:String, ?modsDirectory:String):FlxModding
    {   
        #if (!js || !html5)
        print("Attempting to Initialize FlxModding...");
        if (assetDirectory != null) flixel.system.FlxModding.assetDirectory = assetDirectory;
        if (modsDirectory != null) flixel.system.FlxModding.modsDirectory = modsDirectory;

        if (FileSystem.exists(FlxModding.modsDirectory + "/"))
        {
            #if hscript
            FlxHScript.init();
            #end
            
            enabled = true;
            cache = new FlxCache(allowCaching);
            system = new FlxModding();
            mods = new FlxTypedContainer<FlxModpack>();
        
            #if (flixel >= "3.3.0")
            FlxG.signals.preGameReset.add(function ()
            {
                FlxModding.reload();
            });
            #end

            print("FlxModding Initialized!");
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
        FlxG.log.error("Critical Error! Failed to Initialize FlxModding. Flixel-Modding cannot run properly while targeting JavaScript or HTML5, native targets are required for modding support.");
        //FlxG.log.error("Critical Error! Cannot access required filesystem functionality when targeting JavaScript or HTML5. Native targets are required for modding support.");
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
        print("Attempting to Reload modpacks...");

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

                if (system.exists(modpack.directory() + "/" + metaDirectory))
                {
                    modpack.type = FLIXEL;
                    var metadata:MetadataFormat = Json.parse(system.getText(FlxModding.modsDirectory + "/" + modFile + "/" + FlxModding.metaDirectory));

                    modpack.name = metadata.name;
                    modpack.version = metadata.version;
                    modpack.description = metadata.description;

                    modpack.credits = metadata.credits;

                    modpack.active = metadata.active;
                    modpack.priority = metadata.priority;
                }
                else if (system.exists(modpack.directory() + "/" + metaPolymodDirectory))
                {
                    modpack.type = POLYMOD;
                    var metadata:PolymodMetadataFormat = Json.parse(system.getText(FlxModding.modsDirectory + "/" + modFile + "/" + FlxModding.metaPolymodDirectory));
                    var credits:Array<CreditFormat> = [];

                    for (contributor in metadata.contributors)
                    {
                        credits.push(
                            {
                                name: contributor.name,
                                title: contributor.role,
                                socials: contributor.url
                            });
                    }

                    modpack.name = metadata.title;
                    modpack.version = metadata.mod_version;
                    modpack.description = metadata.description;

                    modpack.credits = credits;

                    modpack.active = true;
                    modpack.priority = 1;
                }
                else
                {
                    modpack.type = FLIXEL;
                    FlxG.log.warn("Failed to locate Metadata, file does not exist. Using fallback/default values instead.");

                    modpack.name = modFile;
                    modpack.version = "1.0.0";
                    modpack.description = "";

                    modpack.credits = [];

                    modpack.active = true;
                    modpack.priority = -1;
                }

                add(modpack);
                print('Added mod: "' + modpack.name + '"');
            }
        }

        FlxModding.sort();
        print("Modpacks Reloaded!");
        postModsReload.dispatch();

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
	 * Sorts all currently loaded modpacks by their priority values.
	 * This is used to determine load or update order, ensuring mods with higher precedence are processed first.
	 */
	public static function sort():Void
	{
		mods.sort((order, mod1, mod2) ->
		{
			return FlxSort.byValues(order, mod1.priority, mod2.priority);
		});    
	}

	/**
	 * Creates a new modpack using the provided metadata and options.
	 * Automatically places the generated modpack inside the active mods directory.
	 * 
	 * @param	fileName			The name of the file/folder to create for the modpack.
	 * @param	iconBitmap			The icon image used to visually represent the modpack.
	 * @param	metadata			Contains modpack information such as the name and structure.
	 *								If you're using a custom-named assets folder, this helps define it.
	 * @param	makeAssetFolders	(Optional) If true, automatically generates empty asset subfolders within the modpack.
	 *								Useful when you want to scaffold common asset paths.
	 */
    public static function create(fileName:String, iconBitmap:BitmapData, metadata:MetadataFormat, ?makeAssetFolders:Bool = true):Void
    {
        #if (!js || !html5)
        print("Attempting to Create a modpack...");
        if (!FileSystem.exists(FlxModding.modsDirectory + "/" + fileName))
        {
            FileSystem.createDirectory(FlxModding.modsDirectory + "/" + fileName);
            File.saveContent(FlxModding.modsDirectory + "/" + fileName + "/" + FlxModding.metaDirectory, FlxModpack.toJsonString(metadata));

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

            add(new FlxModpack(fileName).loadFromMetadata(metadata));
            print("Modpack Created!");
        }
        else
        {
            FlxG.log.warn("The mod: " + fileName + " has already been created. You cannot create a mod with the same name.");
        }
        #end
    }

    /**
     * Clears all mods
     */
    public static function clear():Void
    {
        mods.clear();
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

    public function getAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
    {
        #if (!js || !html5)
        if (StringTools.startsWith(id, "flixel/"))
            return getOpenFLAsset(id, type, useCache);

        var asset:Any = switch type
		{
            case TEXT:
                File.getContent(redirect(id));
			case BINARY:
				File.getBytes(redirect(id));
			
			case IMAGE if ((useCache && FlxModding.cache.enabled) && FlxModding.cache.hasBitmapData(redirect(id))):
				FlxModding.cache.getBitmapData(redirect(id));
			case SOUND if ((useCache && FlxModding.cache.enabled) && FlxModding.cache.hasSound(redirect(id))):
				FlxModding.cache.getSound(redirect(id));
			case FONT if ((useCache && FlxModding.cache.enabled) && FlxModding.cache.hasFont(redirect(id))):
				FlxModding.cache.getFont(redirect(id));
			
			case IMAGE:
				var bitmap = BitmapData.fromFile(redirect(id));
				if (useCache && FlxModding.cache.enabled)
					FlxModding.cache.setBitmapData(redirect(id), bitmap);
				bitmap;
			case SOUND:
				var sound = Sound.fromFile(redirect(id));
				if (useCache && FlxModding.cache.enabled) 
					FlxModding.cache.setSound(redirect(id), sound);
				sound;
			case FONT:
				var font = Font.fromFile(redirect(id));
				if (useCache && FlxModding.cache.enabled)
					FlxModding.cache.setFont(redirect(id), font);
				font;
		}
		
		return asset;
        #end

        return null;
    }

    public function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>
    {
        return Future.withValue(getAsset(id, type, useCache));
    }

    public function exists(id:String, ?type:FlxAssetType):Bool
    {
        #if (!js || !html5)
        if (StringTools.startsWith(id, "flixel/"))
            return OpenFLAssets.exists(id);

        return FileSystem.exists(redirect(id));
        #end

        return false;
    }

    public function list(?type:FlxAssetType):Array<String>
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
        #end

        return null;
    }

    public function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool
    {
        if (StringTools.startsWith(id, "flixel/"))
			OpenFLAssets.isLocal(id, type.toOpenFlType(), OpenFLAssets.cache.enabled && useCache);

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

    function getOpenFLAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
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
        FlxModding.sort();

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
            if ((modpack.active && modpack.alive && modpack.exists) && enabled && FileSystem.exists(modpack.directory() + "/" + id))
            {
                directory = modpack.directory();
            }
        }

        return directory + "/" + id;
        #end
        
        return null;
    }

    static function print(data:Dynamic):Void
    {
        if (debug)
            FlxG.log.add(data);
    }
}

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

typedef PolymodCreditFormat = 
{
    var name:String;
    var role:String;
    var url:String;
}

typedef PolymodMetadataFormat = 
{
    var title:String;
    var mod_version:String;
    var description:String;
    var contributors:Array<PolymodCreditFormat>;
}