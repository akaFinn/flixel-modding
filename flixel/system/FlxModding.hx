package flixel.system;

import flixel.FlxG;
import flixel.group.FlxModpackContainer;
import flixel.system.FlxAssetSystem;
import flixel.system.FlxBaseMetadataFormat;
import flixel.system.FlxBaseModpack;
import flixel.system.FlxMetadataFormat.FlxLegacyMetadataFormat;
import flixel.system.FlxMetadataFormat;
import flixel.system.FlxModpack.FlxLegacyModpack;
import flixel.system.FlxModpack;
import flixel.system.debug.log.LogStyle;
import flixel.system.fileSystems.IFileSystem;
import flixel.system.fileSystems.JsFileSystem;
import flixel.system.fileSystems.RamFileSystem;
import flixel.system.fileSystems.SysFileSystem;
import flixel.system.fileSystems.SysZipFileSystem;
import flixel.system.polymod.PolymodMetadataFormat;
import flixel.system.polymod.PolymodModpack;
import flixel.util.FlxModUtil;
import flixel.util.FlxScriptUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import flixel.util.FlxZipUtil;
import flixel.util.helpers.FlxStringHelper;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.zip.Reader;
import lime.utils.AssetType;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.AssetLibrary;
import openfl.utils.Future;

//TODO: UPDATE THE DOCS!!!!


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
	public static var VERSION:FlxBaseVersion = new FlxModVersion(1, 6, 0, BETA);

    /**
     * Whether Flixel-Modding should print debug info about loading/reloading.
     * Useful for development and troubleshooting mod issues.
     */
    public static var debug:Bool = (FlxModding.VERSION.branch != NONE && FlxModding.VERSION.branch != null);

	/**
	 * Use this to toggle Flixel-Modding between on and off.
	 * You can easily toggle this with e.g.: `FlxModding.enabled = !FlxModding.enabled;`
	 */
	public static var enabled:Bool = true;

	/**
	 * Used for grabbing, loading, or listing assets.
	 * Acts as an alternative to `FlxG.assets`, with support for modded assets.
	 */
	public static var system:FlxModding;

    /**
	 * The container for every single mod available for Flixel-Modding.
	 * All mods are listed here, whether active or not.
	 */
	public static var modpacks:FlxModpackContainer;

	/**
	 * Stores all global signals used by the modding framework.
	 * Acts as the central hub for broadcasting and listening to events.
	 */
	public static var signals:FlxModSignals = new FlxModSignals();

    /**
     * INSTANCE API
     */

    /**
     * Asset system handler for this instance.
     */
    public var assets:FlxAssetSystem;

    /**
     * File system handler for this instance.
     * Lets you swap between different file systems (native, virtual, embedded, etc.)
     * without affecting other instances.
     */
    public var fileSystem:IFileSystem;

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
     * Default asset folder used by the system.
     */
    private static var assetDirectory:String = "assets";

    /**
     * Directory where all installed mods are stored.
     */
    private static var modsDirectory:String = "mods";

    /**
     * Flixel-specific assets directory.
     */
    private static inline var flixelDirectory:String = "flixel";

    /**
     * Registry of all available modding packages.
     */
    private static var modPackages:Array<FlxModPackage> =
    [
        {name: "flixel", cls: FlxModpack, meta: FlxMetadataFormat},
        {name: "polymod", cls: PolymodModpack, meta: PolymodMetadataFormat},
        {name: "legacy", cls: FlxLegacyModpack, meta: FlxLegacyMetadataFormat},
    ];

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
     * // TODO: Fix these comments
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
     * @param   assetDirectory    (Optional) A path that overrides the default directory for game assets.
     *                            Use this if your mod or project relies on a non-standard asset layout.
     * 
     * @param   modsDirectory     (Optional) A path that overrides the default directory used to store mods.
     *                            This folder is where all mods and associated data should reside.
     * 
     * @return                    The initialized FlxModding system so it can be assigned or used directly.
     */
	public static function init(?customModPackages:Array<FlxModPackage>, ?fileSystem:IFileSystem, ?assetDirectory:String, ?modsDirectory:String):FlxModding
    {   
        FlxModding.signals.preInitialization.dispatch();
        FlxModding.log("Attempting to Initialize " + FlxModding.VERSION + "...");

        if (FlxModding.debug != false) FlxModding.log("Attempting to Initialize in prerelease mode...");

        flixel.system.FlxModding.assetDirectory = assetDirectory != null ? assetDirectory : flixel.system.FlxModding.assetDirectory;
        flixel.system.FlxModding.modsDirectory = modsDirectory != null ? modsDirectory : flixel.system.FlxModding.modsDirectory;

        system = new FlxModding();
        modpacks = new FlxModpackContainer();
        FlxG.signals.preGameReset.add(() -> FlxModding.reload());

        buildAssetSystem();
        buildFileSystem(fileSystem);

        if (customModPackages != null)
        {
            for (entry in customModPackages)
            {
                system.registerModPackage(entry);
            }
        }

        if (system.fileSystem.exists(FlxModding.modsDirectory + "/"))
		{
            FlxModding.log("FlxModding Initialized!");
            FlxModding.signals.postInitialization.dispatch();
            return system;
        }
        else
        {
            FlxModding.warn("Mod Directory: '" + FlxModding.modsDirectory + "' not found. Please ensure that the directory has a base file located inside of it. Without this, Flixel-Modding will fail to operate as expected.");
            return null;
        }
    }

    /**
     * Reloads all modpacks found in the mods directory and populates them into `FlxModding.modpacks`.
     * This is automatically triggered during game reset events to ensure all mod data is refreshed.
     * 
     * Useful for reinitializing modpacks without restarting the entire application.
     * 
     * @param   updateMetadata  (Optional) Choose whether to save modpack runtime data to the metadata file.
     */
    public static function reload(?updateMetadata:Bool = true):Void
    {
        signals.preModsReload.dispatch();
        FlxModding.log("Attempting to Reload modpacks...");

        if (system != null && system.initialized != false)
        {
            system.lastReload = FlxG.elapsed;
            system.reloadCount++;

            if (updateMetadata == true && modpacks.length != 0)
            {
                if (enabled != false)
                {
                    FlxModding.update();
                }
            }

            FlxModding.clear();

            if (enabled != false)
            {
                for (modFile in system.fileSystem.readFolder(FlxModding.modsDirectory + "/"))
                {
                    var modFilePath:String = FlxModding.modsDirectory + "/" + modFile;
                    var isZipFile:Bool = StringTools.endsWith(modFilePath, FlxZipUtil.ZIP_PREFIX);

                    if (system.fileSystem.isFolder(modFilePath) != false || isZipFile != false)
                    {
                        if (isZipFile != false) FlxZipUtil.cachedZipFiles.set(modFilePath, FlxZipUtil.unzipFromBytes(system.fileSystem.getFileBytes(modFilePath)));

                        for (entry in modPackages)
                        {
                            if (FlxModding.system.assets.exists(modFilePath + "/" + Reflect.field(entry.meta, "metaPath")))
                            {
                                var modpack = Type.createInstance(entry.cls, [modFile]);
                                modpack.fromMetadata(modpack.metadata.fromDynamic(FlxStringHelper.parseJsonString(FlxModding.system.assets.getText(modpack.metaDirectory()))));
                                add(cast modpack);

                                continue;
                            }
                        }
                    }
                }
            }

            FlxModding.sort();
            FlxModding.log("Modpacks Reloaded!");
            signals.postModsReload.dispatch();
        }
        else
        {
            FlxModding.warn("Failed to Reload modpacks, system is not initialized.");
            FlxModding.init();
        }
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
        signals.preModsUpdate.dispatch();

        if (modpack != null)
        {
            modpack.updateMetadata();
        }
        else
        {
            for (otherModpack in modpacks)
            {
                otherModpack.updateMetadata();
            }
        }

        signals.postModsUpdate.dispatch();
    }

	/**
	 * Sorts all currently loaded modpacks by their ID values.
	 * This is used to determine load or update order, ensuring mods with higher precedence are processed first.
	 */
	public static function sort():Void
	{
		modpacks.sort((order, mod1, mod2) ->
		{
			return FlxSort.byValues(order, mod1.ID, mod2.ID);
		});
	}

    /**
     * Creates a new modpack using the provided metadata and options.
     * Automatically places the generated modpack inside the active mods directory.
     * 
     * @param   fileName            The name of the file/folder to create for the modpack.
     * @param   metadata            Contains modpack information such as the name and structure.
     *                              If you're using a custom-named assets folder, this helps define it.
     * @param   iconBitmap          (Optional) The icon image used to visually represent the modpack.
     * @param   makeAssetFolders    (Optional) If true, automatically generates empty asset subfolders within the modpack.
     *                              Useful when you want to scaffold common asset paths.
     *
     * @return                      A new FlxBaseModpack instance configured with the provided data.
     */
    public static function create(fileName:String, metadata:FlxBaseMetadataFormat, ?iconBitmap:BitmapData, ?makeAssetFolders:Bool = true):FlxBaseModpack<FlxBaseMetadataFormat>
    {
        FlxModding.log("Attempting to Create a modpack...");
        
        if (!system.fileSystem.exists(FlxModding.modsDirectory + "/" + fileName))
        {
            var modpackClass:Class<FlxBaseModpack<Dynamic>> = null;
            var formatClass:Class<FlxBaseMetadataFormat> = null;

            for (entry in modPackages)
            {
                if (entry.meta == Type.getClass(metadata))
                {
                    modpackClass = entry.cls;
                    formatClass = entry.meta;
                }
            }

            if (modpackClass != null && formatClass != null)
            {
                var modpack = Type.createInstance(modpackClass, [fileName]);
                modpack.fromMetadata(cast metadata);

                system.fileSystem.createFolder(FlxModding.modsDirectory + "/", fileName);
                system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(formatClass, "metaPath"), metadata.toJsonString());

                if (makeAssetFolders)
                {
                    for (asset in system.fileSystem.readFolder(FlxModding.assetDirectory))
                    {
                        system.fileSystem.createFolder(FlxModding.modsDirectory + "/" + fileName + "/", asset);
                        system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/" + asset + "/", "content-goes-here.txt", "");
                    }
                }

                if (iconBitmap != null)
                {
                    var encodedBytes = iconBitmap.encode(iconBitmap.rect, new PNGEncoderOptions());
                    var iconData = Bytes.alloc(encodedBytes.length);
                    encodedBytes.position = 0;
                    encodedBytes.readBytes(iconData, 0, encodedBytes.length);

                    system.fileSystem.createFile(FlxModding.modsDirectory + "/" + fileName + "/", Reflect.field(formatClass, "iconPath"), iconData);
                }

                add(cast modpack);
                FlxModding.log("Modpack Created!");
                return cast modpack;
            }
            else
            {
                FlxModding.warn("Modding package has not been registered featuring the metadata format: " + Type.getClassName(Type.getClass(metadata)));
                return null;
            }
        }
        else
        {
            FlxModding.warn("The mod: " + fileName + " has already been created. You cannot create a mod with the same name.");
            return null;
        }

        FlxModding.error("Cannot to Create modpack due to an unknown error.");
        return null;
    }

    // TODO: Fix this function & comment

    /**
     * Unzips raw byte data into a usable FlxBaseModpack instance.
     *
     * @param   bytes   The raw zip archive data containing the modpack files.
     * 
     * @return          A new FlxBaseModpack instance built from the extracted data, or null if extraction fails.
     */
    public static function unzip(fileName:String, bytes:Bytes):FlxBaseModpack<FlxBaseMetadataFormat>
    {
        FlxModding.log("Attempting to Unzip a modpack...");
        FlxModding.warn("This function is unfinished and currently non functional, sorry!");

        return null;
    }

    /**
     * Grabs a modpack based off a file name
     * 
     * @param   fileName   The file name used to find your targeted modpack
     * @return             The modpack you were looking for
     */
    public static function get(fileName:String):FlxBaseModpack<FlxBaseMetadataFormat>
    {
        for (modpack in modpacks.getModpacks())
        {
            if (modpack.file == fileName && FlxModding.exists(fileName))
            {
                return modpack;
            }
        }

        FlxModding.warn("Failed to locate Modpack: " + fileName);
        return null;
    }

    /**
     * Checks if a modpack exists based off a file name
     * 
     * @param   fileName   The file name used to find your targeted modpack
     * @return             The result of weither or not the modpack exists
     */
    public static function exists(fileName:String):Bool
    {
        for (modpack in modpacks.getModpacks())
        {
            if (modpack.file == fileName)
            {
                return true;
            }
        }

        return false;
    }

    /**
     * Clears all mods
     */
    public static function clear():Void
    {
        modpacks.clear();
        signals.onModsCleared.dispatch();
    }

    /**
     * Adds a modpack to the current list of loaded mods.
     * Useful when dynamically inserting modpacks after initialization.
     * 
     * @param   modpack   The modpack instance to be added to the container.
     */
    public static function add(modpack:FlxBaseModpack<FlxBaseMetadataFormat>):Void
    {
        FlxModding.log("Added Modpack: " + modpack.directory());

        modpacks.add(modpack);
        signals.onModAdded.dispatch(modpack);
    }

    /**
     * Removes a modpack from the current list of loaded mods.
     * Call this if you need to disable or unload a mod at runtime.
     * 
     * @param   modpack   The modpack instance to remove from the container.
     */
    public static function remove(modpack:FlxBaseModpack<FlxBaseMetadataFormat>):Void
    {
        FlxModding.log("Removed Modpack: " + modpack.directory());

        modpacks.remove(modpack);
        signals.onModRemoved.dispatch(modpack);
    }

    
    /**
     * Creates a new FlxModding instance, setting up the core systems
     * responsible for managing mods and their assets.
     */
    public function new()
    {
        buildDebuggerTools();
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
        else if (StringTools.contains(id, ":"))
        {
            var library:String = id.split(":")[0];
            var path:String = id.substr(Std.string(library + ":").length);

            return library + ":" + sanitize(path);
        }
        else
        {
            return redirect(id);
        }
    }

    public function redirect(id:String):String
    {
        var directory:String = FlxModding.assetDirectory;

        for (modpack in FlxModding.modpacks)
        {
            if ((modpack.active && modpack.alive && modpack.exists) && FlxModding.enabled)
            {
                var modpackDirectory:String = modpack.directory();

                var appendDirectory:String = modpackDirectory + "/" + FlxStringHelper.DEFAULT_APPEND_PREFIX;
                var mergeDirectory:String = modpackDirectory + "/" + FlxStringHelper.DEFAULT_MERGE_PREFIX;
                var sourceDirectory:String = modpackDirectory + "/" + FlxScriptUtil.DEFAULT_SOURCE_PREFIX;

                for (foundDirectory in [modpackDirectory, sourceDirectory, appendDirectory, mergeDirectory])
                {
                    if (system.fileSystem.exists(foundDirectory + "/" + id))
                    {
                        directory = foundDirectory;
                    }
                }
            }
        }

        return directory + "/" + id;
    }

    /**
     * Retrieves a registered mod package by name.
     * 
     * Searches the internal mod package registry for a matching entry.
     * If found, returns its data (name, modpack class, and metadata class).
     * 
     * @param   modpackName   The name of the mod package to retrieve.
     * 
     * @return                The registered mod package data, or null if no match was found.
     */
    public function getModPackage(modpackName:String):FlxModPackage
    {
        for (entry in modPackages)
        {
            if (entry.name == modpackName)
            {
                return entry;
            }
        }

        FlxModding.warn("Failed to get mod package, mod package could not be found.");
        return null;
    }

    /**
     * Registers a new mod package into the global mod package registry.
     * 
     * This function allows custom modpack implementations and metadata formats
     * to be integrated into the modding system. Once registered, the package
     * can be used for creation, loading, and other mod-related operations.
     * 
     * @param   modPackage   The mod package that you want to be registered
     */
    public function registerModPackage(modPackage:FlxModPackage):Void
    {
        FlxModding.modPackages.push(modPackage);
    }

    /**
     * Unregisters an existing mod package from the global mod package registry.
     * 
     * Removes the specified package so it can no longer be created or accessed.
     * Useful when cleaning up or reloading modding configurations dynamically.
     * 
     * @param   modpackName   The name of the mod package to remove.
     */
    public function unregisterModPackage(modpackName:String):Void
    {
        FlxModding.modPackages.remove(getModPackage(modpackName));
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

    function buildModdedAssetLibrarys():Void
    {   
        for (libraryName in getDefaultAssetLibrarys())
        {
            Assets.registerLibrary(libraryName, new AssetModLibrary(Assets.getLibrary(libraryName)));
        }
    }

    #if hscript
    function buildScriptedInstances():Void
    {
        if (FlxModUtil.getDefinedBool("FLX_SCRIPTING", true))
        {
            var list:Array<String> = [];

            function addFiles(directory:String, prefix = "")
            {
                for (path in fileSystem.readFolder(directory))
                {
                    if (fileSystem.isFolder(directory + "/" + path))
                        addFiles(directory + "/" + path, prefix + path + "/");
                    else
                        list.push(prefix + path);
                }
            }

            addFiles(FlxModding.assetDirectory, FlxModding.assetDirectory + "/");
            addFiles(FlxModding.modsDirectory, FlxModding.modsDirectory + "/");

            FlxModding.signals.postModsReload.add(() ->
            {
                for (asset in list)
                {
                    if (FlxScriptUtil.SCRIPT_FILE_EXTS.contains(Path.extension(asset)))
                    {
                        FlxScriptUtil.buildScript(FlxModding.system.assets.getText(asset));
                    }
                }
            });
        }    
    }
    #end

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
                FlxModding.sort();

                for (modpack in modpacks)
                {
                    FlxG.log.add(modpack.toString());
                }
            });

            FlxG.console.registerFunction("reloadMods", () -> 
            {
                FlxModding.reload();
                FlxG.resetState();
            });

            FlxG.console.registerFunction("sortsMods", () -> 
            {
                FlxModding.sort();
            });

            FlxG.console.registerFunction("toggleModding", () -> 
            {
                FlxModding.enabled = !FlxModding.enabled;
                FlxG.log.advanced("moddingEnabled: " + FlxModding.enabled, LogStyle.CONSOLE);

                FlxG.resetState();
            });

            FlxG.console.registerFunction("activateMods", () -> 
            {
                for (modpack in modpacks)
                {
                    modpack.active = true;
                }

                FlxG.resetState();
            });

            FlxG.console.registerFunction("deactiveMods", () -> 
            {
                for (modpack in modpacks)
                {
                    modpack.active = false;
                }

                FlxG.resetState();
            });
        });
        #end
    }

    static function log(data:Dynamic):Void
    {
        if (FlxModding.debug)
        {
            #if FLX_DEBUG
            FlxG.log.add(data);
            #end
        }
    }

    static function warn(data:Dynamic):Void
    {
        #if FLX_DEBUG
        FlxG.log.warn(data);
        #end
    }

    static function error(data:Dynamic):Void
    {
        #if FLX_DEBUG
        FlxG.log.error(data);
        #end
    }

    static function buildAssetSystem():Void
    {
        system.assets = new FlxAssetSystem();
        system.buildModdedAssetLibrarys();

        #if (flixel >= "5.9.0")
        FlxG.assets.getAssetUnsafe = system.assets.getAsset;
        FlxG.assets.loadAsset = system.assets.loadAsset;
        FlxG.assets.exists = system.assets.exists;

        FlxG.assets.list = system.assets.list;
        FlxG.assets.isLocal = system.assets.isLocal;
        #end
    }

    static function buildFileSystem(?fileSystem:IFileSystem):Void
    {
        if (fileSystem != null)
        {
            system.fileSystem = fileSystem;
        }
        else
        {
            #if (js && html5)
            system.fileSystem = new JsFileSystem();
            #elseif sys
            system.fileSystem = new SysZipFileSystem();
            #else
            system.fileSystem = new RamFileSystem();
            #end
        }

        #if hscript
        system.buildScriptedInstances();
        #end
    }
}

private class FlxModSignals
{
    /**
	 * Signal fired before the system initilizes.
	 */
	public var preInitialization:FlxSignal = new FlxSignal();

	/**
	 * Signal fired after the system initilizes.
	 */
	public var postInitialization:FlxSignal = new FlxSignal();

    /**
	 * Signal fired before modpacks are reloaded.
	 * Useful for saving state or cleaning up.
	 */
	public var preModsReload:FlxSignal = new FlxSignal();

	/**
	 * Signal fired after modpacks are reloaded.
	 * Can be used to refresh UI or data.
	 */
	public var postModsReload:FlxSignal = new FlxSignal();

	/**
	 * Signal fired before modpacks update.
	 * Great for prep work or modifying metadata.
	 */
	public var preModsUpdate:FlxSignal = new FlxSignal();

	/**
	 * Signal fired after modpacks update.
	 * Use this to apply changes or react to updates.
	 */
	public var postModsUpdate:FlxSignal = new FlxSignal();

	/**
	 * Fires when a new modpack is added.
	 * Can be used to initialize systems or load mod-specific content.
	 * Passes the added FlxBaseModpack.
	 */
	public var onModAdded:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

	/**
	 * Fires when a modpack is removed from the system.
	 * Useful for cleaning up resources tied to that mod.
	 * Passes the removed FlxBaseModpack.
	 */
	public var onModRemoved:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

	/**
	 * Fires when all modpacks are cleared from the system at once.
	 * Can be used to reset state, release resources, or reinitialize systems
	 * that depend on active mods.
	 */
	public var onModsCleared:FlxSignal = new FlxSignal();

    /**
     * Signal dispatched when a mod gets activated.
     */
    public var onModActived:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

    /** 
     * Signal dispatched when a mod gets deactivated. 
     */
    public var onModDeactived:FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void> = new FlxTypedSignal<FlxBaseModpack<FlxBaseMetadataFormat>->Void>();

    public function new() {}
}