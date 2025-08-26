package flixel.system;

import flixel.FlxG;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.system.FlxBaseModpack.FlxModpackType;
import flixel.system.assetSystem.FlxAssetSystem;
import flixel.system.assetSystem.IAssetSystem;
import flixel.system.fileSystem.IFileSystem;
import flixel.system.fileSystem.RamFileSystem;
import flixel.system.fileSystem.SysFileSystem;
import flixel.system.fileSystem.WebFileSystem;
import flixel.system.polymod.PolymodMetadataFormat;
import flixel.system.polymod.PolymodModpack;
import flixel.util.FlxScriptUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.io.Bytes;
import lime.utils.AssetType;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.AssetLibrary;
import openfl.utils.Future;


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
 * Common uses include loading mod metadata, accessing registered modpacks, and refreshing assets.
 * 
 * @author akaFinn
 */
@:access(flixel.system.FlxBaseModpack)
class FlxModding
{
    /**
     * PUBLIC API
     */

	/**
	 * The Base Flixel-Modding version, in semantic versioning syntax.
	 */
	public static var VERSION:FlxVersion = new FlxModVersion(1, 5, 0, "beta", "FlxModding");

	/**
	 * Use this to toggle Flixel-Modding between on and off.
	 * You can easily toggle this with e.g.: `FlxModding.enabled = !FlxModding.enabled;`
	 */
	public static var enabled:Bool = true;

    /**
     * Whether Flixel-Modding should print debug info about loading/reloading.
     * Useful for development and troubleshooting mod issues.
     */
    public static var debug:Bool = #if debug true #else false #end;

	/**
	 * Used for grabbing, loading, or listing assets.
	 * Acts as an alternative to `FlxG.assets`, with support for modded assets.
	 */
	public static var system:FlxModding;

	/**
	 * The container for every single mod available for Flixel-Modding.
	 * All mods are listed here, whether active or not.
	 */
	public static var mods:FlxTypedContainer<FlxBaseModpack<FlxBaseMetadataFormat>>;

    /**
     * A toggle for weither or not scripting is enabled on runtime
     */
    public static var scripting:Bool = #if hscript flixel.util.FlxModUtil.getDefinedBool("FLX_SCRIPTING", true); #else false; #end

    /**
     * SIGNALS API
     */

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
	 * Passes the added FlxBaseModpack.
	 */
	public static var onModAdded:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

	/**
	 * Fires when a modpack is removed from the system.
	 * Useful for cleaning up resources tied to that mod.
	 * Passes the removed FlxBaseModpack.
	 */
	public static var onModRemoved:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

	/**
	 * Fires when all modpacks are cleared from the system at once.
	 * Can be used to reset state, release resources, or reinitialize systems
	 * that depend on active mods.
	 */
	public static var onModsCleared:FlxSignal = new FlxSignal();

    /**
     * INSTANCE API
     */

    /**
     * File system handler for this instance.
     * Lets you swap between different file systems (native, virtual, embedded, etc.)
     * without affecting other instances.
     */
    public var fileSystem:IFileSystem;

    /**
     * Asset system handler for this instance.
     * Lets you swap between different asset systems (native, virtual, embedded, etc.)
     * without affecting other instances.
     */
    public var assetSystem:IAssetSystem;

    /**
     * Tracks whether this instance has been initialized.
     * Keeps instance lifecycle separate from global state.
     */
    public var initialized:Bool = false;

    /**
     * Number of times this instance has reloaded its mods/assets.
     * Handy for debugging hot reload behavior.
     */
    public var reloadCount:Int = 0;

    /**
     * Timestamp of the last reload for this instance.
     */
    public var lastReload:Float = -1;

    /**
     * PRIVATE API
     */

    /**
     * Flixel-specific assets directory.
     */
    static inline var flixelDirectory:String = "flixel";

	/**
	 * File extension used for hscript.
	 */
	static var hScriptExt:String = flixel.util.FlxModUtil.getDefinedString("FLX_HSCRIPT_EXT", ".hxs");

	/**
	 * File extension used for Polymod script classes.
	 */
	static var polymodScriptExt:String = flixel.util.FlxModUtil.getDefinedString("FLX_POLYMOD_SCRIPT_EXT", ".hxc");

	/**
	 * File extension used for RuleScript classes.
	 */
	static var ruleScriptExt:String = flixel.util.FlxModUtil.getDefinedString("FLX_RULESCRIPT_EXT", '.rhx');

    /**
     * Flixel’s default modpack class.
     */
    static inline var flixelModpack:Class<FlxModpack> = FlxModpack;

    /**
     * Flixel’s default metadata format class.
     */
    static inline var flixelFormat:Class<FlxMetadataFormat> = FlxMetadataFormat;

    /**
     * Polymod’s default modpack class.
     */
    static inline var polymodModpack:Class<PolymodModpack> = PolymodModpack;

    /**
     * Polymod’s default metadata format class.
     */
    static inline var polymodFormat:Class<PolymodMetadataFormat> = PolymodMetadataFormat;

    /**
     * Default asset folder used by the system.
     */
    static var assetDirectory:String = "assets";

    /**
     * Directory where all installed mods are stored.
     */
    static var modsDirectory:String = "mods";

    /**
     * Base modpack class used for custom implementations.
     */
    static var customModpack:Class<FlxBaseModpack<FlxBaseMetadataFormat>> = FlxBaseModpack;

    /**
     * Base metadata format class for custom modpacks.
     */
    static var customFormat:Class<FlxBaseMetadataFormat> = FlxMetadataFormat;

    /**
     * Initializes Flixel-Modding to enable support for loading and reloading modded assets at runtime.
     * This function sets up internal directories, formats, and systems needed to ensure mods function
     * correctly, including file presence checks and signal hookups for automatic reloads on game reset.
     * 
     * It is highly recommended that you call this method BEFORE instantiating `new FlxGame();`
     * or performing any asset-related operations to avoid misconfiguration issues.
     * 
     * This setup is only available on native targets (like Windows, Mac, or Linux). 
     * It will not function in JS/HTML5 & Flash builds due to file system access restrictions.
     * 
     * @param   customModpack     (Optional) A pre-defined modpack class (extending `FlxBaseModpack`)
     *                            to use instead of automatically generating one. This allows you to
     *                            plug in a fully customized modpack.
     * 
     * @param   customFormat      (Optional) A metadata format class (extending `FlxBaseMetadataFormat`)
     *                            to override the default. Use this if you want mods to load with a
     *                            different metadata schema (e.g. custom JSON structure).
     * 
     * @param   fileSystem        (Optional) A custom file system interface (extending `IFileSystem`) to
     *                            handle how files are read. Useful for embedding mods, virtual file systems,
     *                            or advanced loading scenarios beyond the default behavior.
     * 
     * @param   assetSystem       (Optional) A custom asset system interface (extending `IAssetSystem`)
     *                            to manage asset grabbing and loading. Use this to hook into alternative
     *                            asset pipelines, enable hot-reloading, or redirect asset lookups without
     *                            relying solely on the default OpenFL/Lime systems.
     * 
     * @param   assetDirectory    (Optional) A path that overrides the default directory for game assets.
     *                            Use this if your mod or project relies on a non-standard asset layout.
     * 
     * @param   modsDirectory     (Optional) A path that overrides the default directory used to store mods.
     *                            This folder is where all mods and associated data should reside.
     * 
     * @return                    The initialized FlxModding system so it can be assigned or used directly.
     */
    public static function init(?customModpack:Dynamic, ?customFormat:Class<FlxBaseMetadataFormat>, ?fileSystem:IFileSystem, ?assetSystem:IAssetSystem, ?assetDirectory:String, ?modsDirectory:String):FlxModding
    {   
        FlxModding.log("Attempting to Initialize FlxModding...");

        flixel.system.FlxModding.assetDirectory = assetDirectory != null ? assetDirectory : flixel.system.FlxModding.assetDirectory;
        flixel.system.FlxModding.modsDirectory = modsDirectory != null ? modsDirectory : flixel.system.FlxModding.modsDirectory;

        #if (!js || !flash)
        system = new FlxModding(fileSystem, assetSystem);

        if (system.fileSystem.exists(FlxModding.modsDirectory + "/"))
        {
            flixel.system.FlxModding.customModpack = customModpack != null ? customModpack : flixel.system.FlxModding.customModpack;
            flixel.system.FlxModding.customFormat = customFormat != null ? customFormat : flixel.system.FlxModding.customFormat;
            mods = new FlxTypedContainer<FlxBaseModpack<FlxBaseMetadataFormat>>();

            if (flixel.system.FlxModding.scripting)
            {
                FlxG.signals.postGameStart.add(() ->
                {
                    for (asset in system.assetSystem.list(TEXT))
                    {
                        #if rulescript
                        if (StringTools.endsWith(asset, ruleScriptExt))
                        {
                            FlxScriptUtil.buildRuleScript(system.fileSystem.getFileContent(asset));
                            continue;
                        }
                        #end

                        #if polymod
                        if (StringTools.endsWith(asset, polymodScriptExt))
                        {
                            FlxScriptUtil.buildPolymodScript(system.fileSystem.getFileContent(asset));
                            continue;
                        }
                        #end

                        if (StringTools.endsWith(asset, hScriptExt))
                            FlxScriptUtil.buildHScript(system.fileSystem.getFileContent(asset));
                    }
                });
            }

            FlxModding.log("FlxModding Initialized!");
            return system;
        }
        else
        {
            FlxG.stage.window.alert("Mod Directory: '" + FlxModding.modsDirectory + "' not found. \nPlease ensure that the directory has a base file located inside of it. \nWithout this, Flixel-Modding will fail to operate as expected.", "Critical Error!");
            FlxG.stage.window.close();
            return null;
        }
        #else
        return null;
        #end
    }

    /**
     * Reloads all modpacks found in the mods directory and populates them into `FlxModding.mods`.
     * This is automatically triggered during game reset events to ensure all mod data is refreshed.
     * 
     * Useful for reinitializing modpacks without restarting the entire application.
     * 
     * @param   updateMetadata  (Optional) Choose whether to save modpack runtime data to the metadata file.
     */
    public static function reload(?updateMetadata:Bool = true):Void
    {
        #if (!js || !flash)
        preModsReload.dispatch();
        FlxModding.log("Attempting to Reload modpacks...");
        system.lastReload = FlxG.elapsed;
        system.reloadCount++;

        if (updateMetadata == true && mods.length != 0)
        {
            if (enabled)
            {
                FlxModding.update();
            }
        }

        mods.clear();

        for (modFile in system.fileSystem.readFolder(FlxModding.modsDirectory + "/"))
        {
            if (system.fileSystem.isFolder(FlxModding.modsDirectory + "/" + modFile) && enabled)
            {
                if (FlxModding.system.assetSystem.exists(FlxModding.modsDirectory + "/" + modFile + "/" + Reflect.field(FlxModding.flixelFormat, "metaPath")))
                {
                    var modpack:FlxModpack = Type.createInstance(flixelModpack, [modFile]);
                    modpack.fromMetadata(modpack.metadata.fromDynamicData(Json.parse(FlxModding.system.assetSystem.getText(modpack.metaDirectory()))));
                    add(cast modpack);
                }
                else if (FlxModding.system.assetSystem.exists(FlxModding.modsDirectory + "/" + modFile + "/" + Reflect.field(FlxModding.polymodFormat, "metaPath")))
                {
                    var modpack:PolymodModpack = Type.createInstance(polymodModpack, [modFile]);
                    modpack.fromMetadata(modpack.metadata.fromDynamicData(Json.parse(FlxModding.system.assetSystem.getText(modpack.metaDirectory()))));
                    add(cast modpack);
                }
                else if (FlxModding.system.assetSystem.exists(FlxModding.modsDirectory + "/" + modFile + "/" + Reflect.field(FlxModding.customFormat, "metaPath")))
                {
                    var modpack = Type.createInstance(customModpack, [modFile]);
                    modpack.fromMetadata(modpack.metadata.fromDynamicData(Json.parse(FlxModding.system.assetSystem.getText(modpack.metaDirectory()))));
                    add(cast modpack);
                }
                else
                {
                    FlxModding.warn("Failed to install Modpack, metadata file could not be found. Make sure that the metadata file is spelt correctly and or your custom metadata formatting was properly set.");
                }
            }
        }

        FlxModding.sort();
        FlxModding.log("Modpacks Reloaded!");
        postModsReload.dispatch();
        #else
        FlxModding.error("Failed to reload modpacks while running on a HTML5/JavaScript or Flash build target.");
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
    public static function update(?modpack:FlxBaseModpack<FlxBaseMetadataFormat>):Void
    {
        #if (!js || !flash)
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
        #else
        FlxModding.error("Failed to Update modpacks while running on a HTML5/JavaScript or Flash build target.");
        #end
    }

	/**
	 * Sorts all currently loaded modpacks by their ID values.
	 * This is used to determine load or update order, ensuring mods with higher precedence are processed first.
	 */
	public static function sort():Void
	{
        #if (!js || !flash)
		mods.sort((order, mod1, mod2) ->
		{
			return FlxSort.byValues(order, mod1.ID, mod2.ID);
		});
        #else
        FlxModding.error("Failed to sort modpacks while running on a HTML5/JavaScript or Flash build target.");
        #end  
	}

    /**
     * Creates a new modpack using the provided metadata and options.
     * Automatically places the generated modpack inside the active mods directory.
     * 
     * @param   fileName            The name of the file/folder to create for the modpack.
     * @param   iconBitmap          The icon image used to visually represent the modpack.
     * @param   metadata            Contains modpack information such as the name and structure.
     *                              If you're using a custom-named assets folder, this helps define it.
     * @param   type                (Optional) Defines the type of modpack being created.
     *                              Defaults to `FLIXEL`.
     * @param   makeAssetFolders    (Optional) If true, automatically generates empty asset subfolders within the modpack.
     *                              Useful when you want to scaffold common asset paths.
     *
     * @return                      A new FlxBaseModpack instance configured with the provided data.
     */
    public static function create(fileName:String, iconBitmap:BitmapData, metadata:FlxBaseMetadataFormat, ?type:FlxModpackType = FLIXEL, ?makeAssetFolders:Bool = true):FlxBaseModpack<FlxBaseMetadataFormat>
    {
        #if (!js || !flash)
        FlxModding.log("Attempting to Create a modpack...");
        if (!system.fileSystem.exists(FlxModding.modsDirectory + "/" + fileName))
        {
            switch type
            {
                case FLIXEL:
                    var modpack:FlxModpack = Type.createInstance(flixelModpack, [fileName]);
                    modpack.fromMetadata(cast metadata);

                    system.fileSystem.createFolder(FlxModding.modsDirectory + "/", fileName);
                    system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(FlxModding.flixelFormat, "metaPath"), metadata.toJsonString());

                    var encodedBytes = iconBitmap.encode(iconBitmap.rect, new PNGEncoderOptions());
                    var iconData = Bytes.alloc(encodedBytes.length);
                    encodedBytes.position = 0;
                    encodedBytes.readBytes(iconData, 0, encodedBytes.length);

                    system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(FlxModding.flixelFormat, "iconPath"), iconData);

                    if (makeAssetFolders == true)
                    {
                        for (asset in system.fileSystem.readFolder(FlxModding.assetDirectory))
                        {
                            system.fileSystem.createFolder(FlxModding.modsDirectory + "/" + fileName + "/", asset);
                            system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/" + asset + "/", "content-goes-here.txt", "");
                        }
                    }

                    add(cast modpack);
                    FlxModding.log("Modpack Created!");
                    return cast modpack;

                case POLYMOD:
                    var modpack:PolymodModpack = Type.createInstance(polymodModpack, [fileName]);
                    modpack.fromMetadata(cast metadata);

                    system.fileSystem.createFolder(FlxModding.modsDirectory + "/", fileName);
                    system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(FlxModding.polymodFormat, "metaPath"), metadata.toJsonString());

                    var encodedBytes = iconBitmap.encode(iconBitmap.rect, new PNGEncoderOptions());
                    var iconData = Bytes.alloc(encodedBytes.length);
                    encodedBytes.position = 0;
                    encodedBytes.readBytes(iconData, 0, encodedBytes.length);

                    system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(FlxModding.polymodFormat, "iconPath"), iconData);

                    if (makeAssetFolders == true)
                    {
                        for (asset in system.fileSystem.readFolder(FlxModding.assetDirectory))
                        {
                            system.fileSystem.createFolder(FlxModding.modsDirectory + "/" + fileName + "/", asset);
                            system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/" + asset + "/", "content-goes-here.txt", "");
                        }
                    }

                    add(cast modpack);
                    FlxModding.log("Modpack Created!");
                    return cast modpack;

                case CUSTOM:
                    trace("This aint done chief");
            }

            return null;
        }
        else
        {
            FlxModding.warn("The mod: " + fileName + " has already been created. You cannot create a mod with the same name.");
            return null;
        }
        #else
        FlxModding.error("Failed to create modpack while running on a HTML5/JavaScript or Flash build target.");
        return null;
        #end
    }

    /**
     * Grabs a modpack based off a file name
     * 
     * @param   fileName   The file name used to find your targeted modpack
     * @return             The modpack you were looking for
     */
    public static function get(fileName:String):FlxBaseModpack<FlxBaseMetadataFormat>
    {
        #if (!js || !flash)
        for (modpack in mods.members)
        {
            if (modpack.file == fileName && FlxModding.exists(fileName))
            {
                return modpack;
            }
        }

        FlxModding.warn("Failed to locate Modpack: " + fileName);
        return null;
        #else
        FlxModding.error("Failed to get modpack while running on a HTML5/JavaScript or Flash build target.");
        return null;
        #end
    }

    /**
     * Checks if a modpack exists based off a file name
     * 
     * @param   fileName   The file name used to find your targeted modpack
     * @return             The result of weither or not the modpack exists
     */
    public static function exists(fileName:String):Bool
    {
        #if (!js || !flash)
        for (modpack in mods.members)
        {
            if (modpack.file == fileName)
            {
                return true;
            }
        }

        return false;
        #else
        FlxModding.error("Failed to check if modpack existed while running on a HTML5/JavaScript or Flash build target.");
        return false;
        #end
    }

    /**
     * Clears all mods
     */
    public static function clear():Void
    {
        #if (!js || !flash)
        mods.clear();
        onModsCleared.dispatch();
        #else
        FlxModding.error("Failed to clear modpacks while running on a HTML5/JavaScript or Flash build target.");
        #end
    }

    /**
     * Adds a modpack to the current list of loaded mods.
     * Useful when dynamically inserting modpacks after initialization.
     * 
     * @param   modpack   The modpack instance to be added to the container.
     */
    public static function add(modpack:FlxBaseModpack<FlxBaseMetadataFormat>):Void
    {
        #if (!js || !flash)
        FlxModding.log("Added Modpack: " + modpack.directory());

        mods.add(modpack);
        onModAdded.dispatch(modpack);
        #else
        FlxModding.error("Failed to add modpack while running on a HTML5/JavaScript or Flash build target.");
        #end
    }

    /**
     * Removes a modpack from the current list of loaded mods.
     * Call this if you need to disable or unload a mod at runtime.
     * 
     * @param   modpack   The modpack instance to remove from the container.
     */
    public static function remove(modpack:FlxBaseModpack<FlxBaseMetadataFormat>):Void
    {
        #if (!js || !flash)
        FlxModding.log("Removed Modpack: " + modpack.directory());

        mods.remove(modpack);
        onModRemoved.dispatch(modpack);
        #else
        FlxModding.error("Failed to remove modpack while running on a HTML5/JavaScript or Flash build target.");
        #end
    }
    
    /**
     * Creates a new FlxModding instance, setting up the core systems
     * responsible for managing mods and their assets.
     *
     * @param   fileSystem    (Optional) custom implementation of IFileSystem,
     *                        used to handle mod file access (reading, writing,
     *                        directory traversal, etc.). If null, the default
     *                        file system will be used.
     *
     * @param   assetSystem   (Optional) custom implementation of IAssetSystem,
     *                        responsible for loading, reloading, and resolving
     *                        assets from mods. If null, the default asset system
     *                        will be used.
     */
    public function new(?fileSystem:IFileSystem, ?assetSystem:IAssetSystem)
    {
        this.assetSystem = (assetSystem != null) ? assetSystem : new FlxAssetSystem();

        if (fileSystem != null)
        {
            this.fileSystem = fileSystem;
        }
        else
        {
            #if js
            this.fileSystem = new WebFileSystem();
            #elseif sys
            this.fileSystem = new SysFileSystem();
            #end
        }

        #if (flixel >= "5.9.0")
        FlxG.assets.getAssetUnsafe = this.assetSystem.getAsset;
        FlxG.assets.loadAsset = this.assetSystem.loadAsset;
        FlxG.assets.exists = this.assetSystem.exists;

        FlxG.assets.list = this.assetSystem.list;
        FlxG.assets.isLocal = this.assetSystem.isLocal;
        #end

        for (libraryName in getDefaultAssetLibrarys())
        {
            Assets.registerLibrary(libraryName, new ModAssetLibrary(Assets.getLibrary(libraryName)));
        }

        buildDebuggerTools();
        setupModdingSignals();
        this.initialized = true;
    }

    public function sanitize(id:String):String
    {
        if (StringTools.startsWith(id, FlxModding.modsDirectory + "/") || StringTools.startsWith(id, FlxModding.flixelDirectory + "/"))
        {
            return id;
        }
        else if (StringTools.startsWith(id, FlxModding.assetDirectory + "/"))
        {
            return redirect(id.substr(Std.string(FlxModding.assetDirectory + "/").length));
        }
        else
        {
            return redirect(id);
        }
    }

    public function redirect(id:String):String
    {
        var directory = FlxModding.assetDirectory;

        for (modpack in FlxModding.mods)
        {
            if ((modpack.active && modpack.alive && modpack.exists) && FlxModding.enabled && system.fileSystem.exists(modpack.directory() + "/" + id))
            {
                directory = modpack.directory();
            }
        }

        return directory + "/" + id;
        
        return null;
    }

    function getDefaultAssetLibrarys():Array<String>
    {
        var result:Array<String> = [];

        @:privateAccess
        for (key in Assets.libraries.keys())
        {
            result.push(key);
        }

        return result;
    }

    function buildDebuggerTools():Void
    {
        #if FLX_DEBUG
        var label = new TextField();
		label.height = 20;
		label.selectable = false;
		label.y = -9;
		label.multiline = false;
		label.embedFonts = true;
		label.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEBUGGER, 12, 0xffffff);
		label.autoSize = TextFieldAutoSize.LEFT;
		label.text = Std.string(FlxModding.VERSION);

        FlxG.signals.postGameStart.addOnce(() -> 
        {
            FlxG.debugger.addButton(LEFT, null, () -> FlxG.openURL("https://lib.haxe.org/p/flixel-modding/")).addChild(label);

            FlxG.console.registerFunction("listMods", () -> 
            {
                for (modpack in mods)
                {
                    FlxG.log.add(modpack.directory() + ", " + Type.getClassName(Type.getClass(modpack)).split(".").pop() + ", active: " + modpack.active);
                }
            });

            FlxG.console.registerFunction("listActiveMods", () -> 
            {
                for (modpack in mods)
                {
                    if (modpack.active)
                        FlxG.log.add(modpack.directory() + ", " + Type.getClassName(Type.getClass(modpack)).split(".").pop());
                }
            });
        });
        #end
    }

    function setupModdingSignals():Void
    {
        FlxG.signals.preGameReset.add(() ->
        {
            FlxModding.reload();
        });

        FlxG.signals.preStateSwitch.add(() ->
        {
            assetSystem.clear();
        });
    }

    static function log(data:Dynamic):Void
    {
        if (debug)
            FlxG.log.add(data); 
    }

    static function warn(data:Dynamic):Void
    {
        FlxG.log.warn(data); 
    }

    static function error(data:Dynamic):Void
    {
        FlxG.log.error(data); 
    }
}

/**
 * @author akaFinn
 * @since 1.4.0
 */
@:access(lime.utils.AssetLibrary)
@:access(flixel.system.FlxModding)
private class ModAssetLibrary extends AssetLibrary
{
    public var defaultLibrary:lime.utils.AssetLibrary;

    public function new(?defaultLibrary:lime.utils.AssetLibrary, ?filterFlixel:Bool = true)
    {
        super();

        if (defaultLibrary != null) 
        {
            this.defaultLibrary = defaultLibrary;

            for (key in defaultLibrary.classTypes.keys())
                if (StringTools.startsWith(key, FlxModding.flixelDirectory) == filterFlixel)
                    this.classTypes.set(key, defaultLibrary.classTypes.get(key));

            for (key in defaultLibrary.types.keys())
                if (StringTools.startsWith(key, FlxModding.flixelDirectory) == filterFlixel)
                    this.types.set(key, defaultLibrary.types.get(key));
        }
    }

    override public function getAsset(id:String, type:String):Dynamic
    {
        if (isFlixelAsset(id))
            return getAssetDefault(id, type);
        else
            return getAssetModded(id, type);
    }

    public function getAssetDefault(id:String, type:String):Dynamic
    {
        return super.getAsset(id, type);
    }

    public function getAssetModded(id:String, type:String):Dynamic
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: getBytes(id);
            case TEXT: getText(id);
			case IMAGE: getImage(id);
            case FONT: getFont(id);
			case MUSIC, SOUND: getAudioBuffer(id);

			default: FlxG.log.error("Unknown asset type: " + type); null;
		}
    }

    override public function loadAsset(id:String, type:String):Future<Dynamic>
    {
        if (isFlixelAsset(id))
            return loadAssetDefault(id, type);
        else
            return loadAssetModded(id, type);
    }

    public function loadAssetDefault(id:String, type:String):Future<Dynamic>
    {
        return super.loadAsset(id, type);
    }

    public function loadAssetModded(id:String, type:String):Future<Dynamic>
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: loadBytes(id);
            case TEXT: loadText(id);
			case IMAGE: loadImage(id);
            case FONT: loadFont(id);
			case MUSIC, SOUND: loadAudioBuffer(id);

			default: FlxG.log.error("Unknown asset type: " + type); null;
		}
    }

    override public function exists(id:String, type:String):Bool
    {
        if (isFlixelAsset(id))
            return existsDefault(id, type);
        else
            return existsModded(id, type);
    }

    public function existsDefault(id:String, type:String):Bool
    {
        return super.exists(id, type);
    }

    public function existsModded(id:String, type:String):Bool
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: FlxModding.system.assetSystem.exists(id, BINARY);
			case TEXT: FlxModding.system.assetSystem.exists(id, TEXT);
			case IMAGE: FlxModding.system.assetSystem.exists(id, IMAGE);
            case FONT: FlxModding.system.assetSystem.exists(id, FONT);
			case MUSIC, SOUND: FlxModding.system.assetSystem.exists(id, SOUND);

			default: FlxG.log.error("Unknown asset type: " + type); false;
		}
    }

    override public function list(type:String):Array<String>
    {
        var result:Array<String>;

        if (type != null)
        {
            result = switch (cast(type, AssetType))
		    {
			    case BINARY: FlxModding.system.assetSystem.list(BINARY);
			    case TEXT: FlxModding.system.assetSystem.list(TEXT);
			    case IMAGE: FlxModding.system.assetSystem.list(IMAGE);
                case FONT: FlxModding.system.assetSystem.list(FONT);
			    case MUSIC, SOUND: FlxModding.system.assetSystem.list(SOUND);

			    default: FlxG.log.error("Unknown asset type: " + type); [];
		    }
        }
        else
        {
            result = FlxModding.system.assetSystem.list();
        }

        return result;
    }

    override public function isLocal(id:String, type:String):Bool
    {
        if (isFlixelAsset(id))
            return isLocalDefault(id, type);
        else
            return isLocalModded(id, type);
    }

    public function isLocalDefault(id:String, type:String):Bool
    {
        return super.isLocal(id, type);
    }

    public function isLocalModded(id:String, type:String):Bool
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: FlxModding.system.assetSystem.isLocal(id, BINARY);
			case TEXT: FlxModding.system.assetSystem.isLocal(id, TEXT);
			case IMAGE: FlxModding.system.assetSystem.isLocal(id, IMAGE);
            case FONT: FlxModding.system.assetSystem.isLocal(id, FONT);
			case MUSIC, SOUND: FlxModding.system.assetSystem.isLocal(id, SOUND);

			default: FlxG.log.error("Unknown asset type: " + type); false;
		}
    }

    override public function getPath(id:String):String
    {
        if (isFlixelAsset(id))
            return getPathDefault(id);
        else
            return getPathModded(id);
    }

    public function getPathDefault(id:String):String
    {
        return super.getPath(id);    
    }

    public function getPathModded(id:String):String
    {
        return FlxModding.system.sanitize(id);    
    }

    override public function getText(id:String):String
    {
        if (isFlixelAsset(id))
            return getTextDefault(id);
        else
            return getTextModded(id);
    }

    public function getTextDefault(id:String):String
    {
        return super.getText(id);
    }

    public function getTextModded(id:String):String
    {
        return FlxModding.system.assetSystem.getText(id);    
    }

    override public function getBytes(id:String):lime.utils.Bytes
    {
        if (isFlixelAsset(id))
            return getBytesDefault(id);
        else
            return getBytesModded(id);
    }

    public function getBytesDefault(id:String):lime.utils.Bytes
    {
        return super.getBytes(id);
    }

    public function getBytesModded(id:String):lime.utils.Bytes
    {
        return lime.utils.Bytes.fromBytes(FlxModding.system.assetSystem.getBytes(id));
    }

    override public function getImage(id:String):lime.graphics.Image
    {
        if (isFlixelAsset(id))
            return getImageDefault(id);

        return lime.graphics.Image.fromBitmapData(FlxModding.system.assetSystem.getBitmapData(id));
    }

    public function getImageDefault(id:String):lime.graphics.Image
    {
        return super.getImage(id);    
    }

    public function getImageModded(id:String):lime.graphics.Image
    {
        return lime.graphics.Image.fromBitmapData(FlxModding.system.assetSystem.getBitmapData(id));
    }

    override public function getAudioBuffer(id:String):lime.media.AudioBuffer
    {
        if (isFlixelAsset(id))
            return getAudioBufferDefault(id);
        else
            return getAudioBufferModded(id);
    }

    public function getAudioBufferDefault(id:String):lime.media.AudioBuffer
    {
        return super.getAudioBuffer(id);
    }

    public function getAudioBufferModded(id:String):lime.media.AudioBuffer
    {
        @:privateAccess
        return FlxModding.system.assetSystem.getSound(id).__buffer;    
    }

    override public function getFont(id:String):lime.text.Font
    {
        if (isFlixelAsset(id))
            return getFontDefault(id);
        else
            return getFontModded(id);
    }

    public function getFontDefault(id:String):lime.text.Font
    {
        return super.getFont(id);
    }

    public function getFontModded(id:String):lime.text.Font
    {
        return FlxModding.system.assetSystem.getFont(id);
    }

    override public function loadText(id:String):Future<String>
    {
        if (isFlixelAsset(id))
            return loadTextDefault(id);
        else
            return loadTextModded(id);
    }

    public function loadTextDefault(id:String):Future<String>
    {
        return super.loadText(id);    
    }

    public function loadTextModded(id:String):Future<String>
    {
        return Future.withValue(getTextModded(id));
    }

    override public function loadBytes(id:String):Future<lime.utils.Bytes>
    {
        if (isFlixelAsset(id))
            return loadBytesDefault(id);
        else
            return loadBytesModded(id);
    }

    public function loadBytesDefault(id:String):Future<lime.utils.Bytes>
    {
        return super.loadBytes(id);    
    }

    public function loadBytesModded(id:String):Future<lime.utils.Bytes>
    {
        return Future.withValue(getBytesModded(id));
    }

    override public function loadImage(id:String):Future<lime.graphics.Image>
    {
        if (isFlixelAsset(id))
            return loadImageDefault(id);
        else
            return loadImageModded(id);
    }

    public function loadImageDefault(id:String):Future<lime.graphics.Image>
    {
        return super.loadImage(id);
    }

    public function loadImageModded(id:String):Future<lime.graphics.Image>
    {
        return Future.withValue(getImageModded(id));
    }

    override public function loadAudioBuffer(id:String):Future<lime.media.AudioBuffer>
    {
        if (isFlixelAsset(id))
            return loadAudioBufferDefault(id);
        else
            return loadAudioBufferModded(id);
    }

    public function loadAudioBufferDefault(id:String):Future<lime.media.AudioBuffer>
    {
        return super.loadAudioBuffer(id);    
    }

    public function loadAudioBufferModded(id:String):Future<lime.media.AudioBuffer>
    {
        return Future.withValue(getAudioBufferModded(id));
    }

    override public function loadFont(id:String):Future<lime.text.Font>
    {
        if (isFlixelAsset(id))
            return loadFontDefault(id);
        else
            return loadFontModded(id);
    }

    public function loadFontDefault(id:String):Future<lime.text.Font>
    {
        return super.loadFont(id);
    }

    public function loadFontModded(id:String):Future<lime.text.Font>
    {
        return Future.withValue(getFontModded(id));    
    }

    function isFlixelAsset(id:String):Bool
    {
        return StringTools.startsWith(id, FlxModding.flixelDirectory);
    }
}

private class FlxModVersion extends FlxVersion
{
	public var branch(default, null):String;
	public var display(default, null):String;

	public function new(Major:Int, Minor:Int, Patch:Int, ?Branch:String, ?Display:String)
	{
        super(Major, Minor, Patch);

        branch = Branch;
        display = "";

        if (Display != null)
            display = Display + " ";
	}

	override public function toString():String
	{
		if (branch != null)
            return '$display$major.$minor.$patch-$branch';
        else
            return '$display$major.$minor.$patch';
	}   
}