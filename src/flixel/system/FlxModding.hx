package flixel.system;

import flixel.system.hscript.FlxScriptModule;
import flixel.FlxG;
import flixel.system.FlxModpack;
import flixel.system.FlxFileSystem;
import flixel.system.FlxBaseModpack;
import flixel.system.FlxLegacyModpack;
import flixel.group.FlxModpackContainer;
import flixel.system.polymod.PolymodModpack;
import flixel.system.macros.FlxModMacro;
import flixel.util.helpers.FlxStringHelper;
import flixel.util.FlxScriptUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import flixel.util.FlxZipUtil;
import haxe.semver.Version;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.JPEGEncoderOptions;
import openfl.display.PNGEncoderOptions;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.ByteArray;
import openfl.utils.Object;

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
 */
@:access(flixel.system.FlxBaseModpack)
class FlxModding
{
    /**
     * CONSTANT API
     */

    /**
	 * The version of the library
	 */
	public static final VERSION:Version = "1.6.0";

    /**
	 * The title of the library
	 */
	public static final LIBRARY_TITLE:String = "flixel-modding";

    /**
     * Linked for flixel-modding's haxelib page
     */
    public static final HAXELIB_LINK:String = "https://lib.haxe.org/p/flixel-modding/";

    /**
     * Linked for flixel-modding's github page
     */
    public static final GITHUB_LINK:String = "https://github.com/akaFinn/flixel-modding";

    /**
     * PUBLIC API
     */

	/**
	 * Use this to toggle Flixel-Modding between on and off.
	 * You can easily toggle this with e.g.: `FlxModding.enabled = !FlxModding.enabled;`
	 */
	public static var enabled:Bool = true;

    /**
     * Whether Flixel-Modding should print debug info about loading/reloading.
     * Useful for development and troubleshooting mod issues.
     */
    public static var debug:Bool = #if FLX_MODDING_DEBUG true #else false #end;

	/**
	 * Current running instance of FlxModding.
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
     * Tracks whether this instance has been initialized.
     * Keeps instance lifecycle separate from global state.
     */
    public var initialized:Bool = false;

    /**
     * Blacklisted directorys that will not be affected by modpacks.
     */
    private var blacklistedDirectorys:Array<String> = [];
    
    /**
     * Registry of all available modpack classes.
     */
    private var modpackClasses:Array<Class<FlxBaseModpack>> = [];

    /**
     * PRIVATE API
     */

    /**
     * Directory that contain assets.
     */
    private static var ASSETS_DIRECTORY:String = "assets";

    /**
     * Directory that contain installed mods.
     */
    private static var MODS_DIRECTORY:String = "mods";

    /**
     * Flixel-specific assets directory.
     */
    private static var FLIXEL_DIRECTORY:String = "flixel";

    /**
     * Initializes the Flixel-Modding system for runtime mod support.
     *
     * This function sets up the internal modding environment, including the
     * mods and assets directories, modpack container, and necessary signal
     * hooks to support automatic reloading of modded assets during game resets.
     *
     * It is strongly recommended to call this method before creating a new
     * `FlxGame` instance or performing any asset-related operations to
     * ensure proper configuration and avoid runtime issues.
     *
     * Behavior:
     * - Sets the active assets and mods directories, using overrides if provided.
     * - Instantiates the `FlxModding` system and modpack container.
     * - Hooks into `FlxG.signals.preGameReset` to automatically reload modpacks.
     * - Builds the file and asset systems required for mod loading.
     * - Configures Polymod integration if enabled.
     * - Checks for the existence of the mods directory, creating it if missing,
     *   and adds a placeholder file to indicate where mods should be placed.
     * - Dispatches pre- and post-initialization signals for custom logic.
     *
     * @param   assetDirectory   (Optional) Override path for base game assets.
     * @param   modsDirectory    (Optional) Override path for the mods folder.
     *
     * @return  The initialized `FlxModding` instance for reference or reassignment.
     */
	public static function init(?assetDirectory:String, ?modsDirectory:String):FlxModding
    {   
        FlxModding.signals.preInitialization.dispatch();
        FlxModding.log("Attempting to Initialize FlxModding " + FlxModding.VERSION + "...");

        if (FlxModding.debug != false) 
            FlxModding.log("Attempting to Initialize in prerelease mode...");

        FlxModding.ASSETS_DIRECTORY = assetDirectory != null ? assetDirectory : FlxModding.ASSETS_DIRECTORY;
        FlxModding.MODS_DIRECTORY = modsDirectory != null ? modsDirectory : FlxModding.MODS_DIRECTORY;

        FlxModding.system = new FlxModding();
        FlxModding.modpacks = new FlxModpackContainer();
        FlxG.signals.preGameReset.add(() -> FlxModding.reload());

        buildFileSystem();
        buildAssetSystem();

        #if polymod
        configureWithPolymod();
        #end
 
        if (!FlxFileSystem.exists(FlxModding.MODS_DIRECTORY + "/"))
        {
            FlxModding.warn("Failed to detect Mod Directory: '" + FlxModding.MODS_DIRECTORY + "', creating new directory.");

            FlxFileSystem.createFolder(FlxModding.MODS_DIRECTORY + "/");
            FlxFileSystem.setFileContent(FlxModding.MODS_DIRECTORY + "/mods-go-here.txt", "");
        }

        FlxModding.system.initialized = true;
        FlxModding.log("FlxModding Initialized!");
        FlxModding.signals.postInitialization.dispatch();
        return system;
    }

    /**
     * Reloads all modpacks from the mods directory.
     *
     * This function clears the current runtime modpack list and rescans the
     * global mods directory to rebuild it. Each discovered modpack is matched
     * against the registered modpack classes and instantiated accordingly.
     *
     * In addition to loading folder-based modpacks, this function also detects
     * compressed mod archives. If a valid zip archive is encountered, it will
     * automatically be extracted into a folder inside the mods directory before
     * being processed as a normal modpack.
     *
     * This function is typically triggered during game reset events to ensure
     * that all mod content is refreshed without restarting the application.
     */
    public static function reload():Void
    {
        signals.preModsReload.dispatch();
        FlxModding.log("Attempting to Reload modpacks...");

        if (system != null && system.initialized != false)
        {
            if (modpacks.length != 0)
                FlxModding.clear();

            if (enabled != false)
            {
                for (modFileName in FlxFileSystem.readFolder(FlxModding.MODS_DIRECTORY + "/"))
                {
                    var modpackClass:Class<FlxBaseModpack> = null;
                    var modFilePath:String = FlxModding.MODS_DIRECTORY + "/" + modFileName;
                    
                    if (FlxFileSystem.isFile(modFilePath))
                    {
                        var modFileBytes:Bytes = FlxFileSystem.getFileBytes(modFilePath);

                        if (FlxZipUtil.getZipFormat(modFileBytes) != UNKNOWN)
                        {
                            if (!FlxFileSystem.exists(Path.withoutExtension(modFilePath)))
                            {
                                FlxFileSystem.deleteFile(modFilePath);
                                FlxFileSystem.unzipBytes(Path.withoutExtension(modFilePath), modFileBytes);

                                for (cls in system.listModpackClasses())
                                {
                                    if (FlxFileSystem.exists(Path.withoutExtension(modFilePath) + "/" + Reflect.field(cls, FlxModMacro.DEFAULT_META_MACRO_PREFIX)))
                                    {
                                        modpackClass = cls;
                                        break;
                                    }
                                }

                                add(FlxBaseModpack.fromModpackClass(Path.withoutExtension(modFileName), modpackClass));
                            }
                            else
                            {
                                FlxModding.warn("Failed to Unzip Modpack while Reloading, modpack already exists unzipped.");
                            }
                        }
                    }
                    else if (FlxFileSystem.isFolder(modFilePath))
                    {
                        for (cls in system.listModpackClasses())
                        {
                            if (FlxFileSystem.exists(modFilePath + "/" + Reflect.field(cls, FlxModMacro.DEFAULT_META_MACRO_PREFIX)))
                            {
                                modpackClass = cls;
                                break;
                            }
                        }

                        add(FlxBaseModpack.fromModpackClass(modFileName, modpackClass));
                    }
                }
            }

            FlxModding.sort();
            FlxModding.log("Modpacks Reloaded!");
            signals.postModsReload.dispatch();
        }
        else
        {
            FlxModding.warn("Failed to Reload Modpacks, system is not initialized.");
        }
    }

    /**
     * Sorts all loaded modpacks based on their order values.
     *
     * This function determines the load and update order of modpacks, ensuring
     * that those with higher precedence (lower or higher order depending on sorting
     * logic) are processed before others. It uses `FlxSort.byValues` to perform
     * a stable comparison between mod order's.
     *
     * Sorting modpacks correctly is important to maintain consistent behavior
     * when multiple mods modify the same assets or systems.
     */
	public static function sort():Void
	{
		FlxModding.modpacks.sort((order:Int, modpack1:FlxBaseModpack, modpack2:FlxBaseModpack) ->
		{
			return FlxSort.byValues(order, modpack1.order, modpack2.order);
		});
	}

    /**
     * Creates and registers a new modpack within the mods directory.
     *
     * This function generates the folder structure for a modpack, writes its
     * metadata file, optionally scaffolds asset directories, and saves an icon
     * if one is provided. Once the modpack is successfully created, it is also
     * registered into the active modpack registry.
     *
     * The modpack class must already be registered within the modding system.
     * If the class is not registered, or a modpack with the same name already
     * exists, the creation process will fail.
     *
     * @param   fileName           The name of the modpack directory to create.
     * @param   modpackClass       The registered modpack class used to construct and define the modpack.
     * @param   metadata           (Optional) Dynamic metadata applied to the modpack before serialization.
     * @param   iconBitmap         (Optional) Bitmap image used as the modpack icon.
     * @param   makeAssetFolders   (Optional) If true, automatically generates empty asset subdirectories.
     *
     * @return  A configured `FlxBaseModpack` instance if creation succeeds, otherwise `null`.
     */
    public static function create(fileName:String, modpackClass:Class<FlxBaseModpack>, ?metadata:Dynamic = null, ?iconBitmap:BitmapData = null, ?makeAssetFolders:Bool = true):FlxBaseModpack
    {
        FlxModding.log("Attempting to Create a modpack...");
        
        if (system != null && system.initialized != false)
        {
            if (!FlxFileSystem.exists(FlxModding.MODS_DIRECTORY + "/" + fileName))
            {
                if (system.hasModpackClass(modpackClass))
                {
                    var modpack:FlxBaseModpack = FlxBaseModpack.fromModpackClass(fileName, modpackClass);
                    modpack.fromDynamic(metadata);

                    FlxFileSystem.createFolder(FlxModding.MODS_DIRECTORY + "/" + fileName);
                    FlxFileSystem.setFileContent(FlxModding.MODS_DIRECTORY + "/" + fileName + "/" + Reflect.field(modpackClass, FlxModMacro.DEFAULT_META_MACRO_PREFIX), modpack.toJsonString());

                    if (makeAssetFolders != false)
                    {
                        for (asset in FlxFileSystem.readFolder(FlxModding.ASSETS_DIRECTORY))
                        {
                            FlxFileSystem.createFolder(FlxModding.MODS_DIRECTORY + "/" + fileName + "/" + asset);
                            FlxFileSystem.setFileContent(FlxModding.MODS_DIRECTORY + "/" + fileName + "/" + asset + "/content-goes-here.txt", "");
                        }
                    }

                    if (iconBitmap != null)
                    {
                        var compressor:Object = null;

                        switch (Path.extension(Reflect.field(modpackClass, FlxModMacro.DEFAULT_ICON_MACRO_PREFIX)))
                        {
                            case "png": compressor = new PNGEncoderOptions();
                            case "jpg" | "jpeg": compressor = new JPEGEncoderOptions();
                        }

                        if (compressor != null)
                        {
                            var encodedBytes:ByteArray = iconBitmap.encode(iconBitmap.rect, compressor);
                            var iconData:Bytes = Bytes.alloc(encodedBytes.length);

                            encodedBytes.position = 0;
                            encodedBytes.readBytes(iconData, 0, encodedBytes.length);

                            FlxFileSystem.setFileBytes(FlxModding.MODS_DIRECTORY + "/" + fileName + "/" + Reflect.field(modpackClass, FlxModMacro.DEFAULT_ICON_MACRO_PREFIX), iconData);
                        }
                        else
                        {
                            FlxModding.warn("Failed to Create Modpack Icon, proper compressor for icon bitmap could not be found.");
                        }
                    }

                    add(modpack);
                    FlxModding.log("Modpack Created!");
                    return modpack;
                }
                else
                {
                    FlxModding.warn("Failed to Create Modpack, Modpack Class is not registered. Please register Modpack Class into the system.");
                    return null;
                }
            }
            else
            {
                FlxModding.warn("Failed to Create Modpack, the Modpack: " + fileName + " has already been created, you cannot create a mod with the same name.");
                return null;
            }
        }
        else
        {
            FlxModding.warn("Failed to Create Modpack, system is not initialized.");
            return null;
        }

        FlxModding.error("Failed to Create Modpack due to an unknown error.");
        return null;
    }

    /**
     * Unzips raw byte data into a usable FlxBaseModpack instance.
     *
     * @param   bytes   The raw zip archive data containing the modpack files.
     * 
     * @return  A new FlxBaseModpack instance built from the extracted data, or null if extraction fails.
     */
    public static function unzip(fileBytes:Bytes, ?fileName:String):FlxBaseModpack
    {
        FlxModding.log("Attempting to Unzip a modpack...");
        
        if (system != null && system.initialized != false)
        {
            if (FlxZipUtil.getZipFormat(fileBytes) != UNKNOWN)
            {
                if (fileName == null || fileName == "")
                    fileName = "_mod@" + FlxG.random.int(111111, 999999);

                var modFilePath:String = FlxModding.MODS_DIRECTORY + "/" + fileName;
                var modpackClass:Class<FlxBaseModpack> = null;

                if (!FlxFileSystem.exists(Path.withoutExtension(modFilePath)))
                {
                    FlxFileSystem.unzipBytes(Path.withoutExtension(modFilePath), fileBytes);

                    for (cls in system.listModpackClasses())
                    {
                        if (FlxFileSystem.exists(Path.withoutExtension(modFilePath) + "/" + Reflect.field(cls, FlxModMacro.DEFAULT_META_MACRO_PREFIX)))
                        {
                            modpackClass = cls;
                            break;
                        }
                    }

                    FlxModding.log("Modpack Unzipped!");
                    var modpack:FlxBaseModpack = FlxBaseModpack.fromModpackClass(Path.withoutExtension(fileName), modpackClass);
                    add(modpack);

                    return modpack;
                }
                else
                {
                    FlxModding.warn("Failed to Unzip Modpack, modpack already exists unzipped.");
                    return null;
                }
            }
            else
            {
                FlxModding.warn("Failed to Unzip Modpack, file is not a recognized zip format.");
                return null;
            }
        }
        else
        {
            FlxModding.warn("Failed to Unzip Modpack, system is not initialized.");
            return null;
        }

        FlxModding.error("Failed to Unzip Modpack due to an unknown error.");
        return null;
    }

    /**
     * Grabs a modpack based off a file name
     * 
     * @param   fileName   The file name used to find your targeted modpack
     * @return             The modpack you were looking for
     */
    public static function get(fileName:String):FlxBaseModpack
    {
        for (modpack in modpacks.getModpacks())
        {
            if (modpack.fileName == fileName && FlxModding.exists(fileName))
            {
                return modpack;
            }
        }

        FlxModding.warn("Failed to Get Modpack: " + fileName);
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
            if (modpack.fileName == fileName)
            {
                return true;
            }
        }

        return false;
    }

    /**
     * Clears all modpacks
     */
    public static function clear():Void
    {
        if (FlxModding.modpacks.length != 0)
        {
            for (modpack in FlxModding.modpacks.getModpacks())
            {
                modpack.saveMetadataFile();
            }

            modpacks.clear();
            signals.onModsCleared.dispatch();
        }
        else
        {
            FlxModding.warn("Failed to Clear Modpacks, no modpacks have been added.");
        }
    }

    /**
     * Adds a modpack to the current list of loaded mods.
     * Useful when dynamically inserting modpacks after initialization.
     * 
     * @param   modpack   The modpack instance to be added to the container.
     */
    public static function add(modpack:FlxBaseModpack):Void
    {
        FlxModding.log("Added Modpack: " + modpack.getDirectory());

        modpacks.add(modpack);
        signals.onModAdded.dispatch(modpack);
        FlxModding.sort();
    }

    /**
     * Removes a modpack from the current list of loaded mods.
     * Call this if you need to disable or unload a mod at runtime.
     * 
     * @param   modpack   The modpack instance to remove from the container.
     */
    public static function remove(modpack:FlxBaseModpack):Void
    {
        FlxModding.log("Removed Modpack: " + modpack.getDirectory());

        modpacks.remove(modpack);
        signals.onModRemoved.dispatch(modpack);
        FlxModding.sort();
    }

    
    /**
     * Creates a new FlxModding instance, setting up the core systems
     * responsible for managing mods and their assets.
     */
    public function new()
    {
        buildGithubLabel();

        if (FlxModding.debug)
        {
            buildDebugCommands();
        }

        // TODO: Remove this bullshit.
        this.registerModpackClass(FlxModpack);
        this.registerModpackClass(FlxLegacyModpack);
        this.registerModpackClass(PolymodModpack);
    }

    /**
     * Resolves and sanitizes an asset identifier to ensure it points to a valid,
     * loadable path within the Flixel-Modding system.
     * 
     * This method performs several checks and transformations to determine
     * where an asset should be loaded from
     * 
     * This function helps ensure that assets can be dynamically resolved from
     * both the base game and any enabled modpacks without requiring manual path handling.
     * 
     * @param   id   The raw asset identifier or relative file path to sanitize.
     * 
     * @return   A valid, fully-resolved file path or asset ID ready for loading.
     */
    public function sanitize(id:String):String
    {
        if (StringTools.startsWith(id, FlxModding.MODS_DIRECTORY + "/"))
        {
            return redirect(id.substr(Std.string(FlxModding.MODS_DIRECTORY + "/").length), FlxModding.MODS_DIRECTORY);
        }
        else if (StringTools.startsWith(id, FlxModding.ASSETS_DIRECTORY + "/"))
        {
            return redirect(id.substr(Std.string(FlxModding.ASSETS_DIRECTORY + "/").length), FlxModding.ASSETS_DIRECTORY);
        }
        else if (StringTools.contains(id, ":"))
        {
            var library:String = id.split(":")[0];
            var path:String = id.substr(Std.string(library + ":").length);

            return library + ":" + sanitize(path);
        }

        return redirect(id);
    }

    /**
     * Redirects an asset identifier to the correct directory based on currently
     * active modpacks. This allows Flixel-Modding to dynamically resolve assets
     * from multiple sources without requiring explicit directory management.
     * 
     * The method iterates through each active and existing modpack (when modding
     * is enabled) and searches several subdirectories for a matching file
     * 
     * If the asset exists in any of these locations, the directory is updated
     * accordingly so that the final returned path correctly reflects the file’s
     * real location on disk.
     * 
     * @param   id   The relative asset path or identifier to redirect.
     * 
     * @return   A full file path pointing to the asset’s actual location, either
     *           within a modpack directory or the default asset directory.
     */
    public function redirect(id:String, ?baseDirectory:String = ""):String
    {
        var isBlacklisted:Bool = this.hasBlacklistedDirectory(id) || this.hasBlacklistedDirectory(baseDirectory + "/" + id);

        if (FlxModding.enabled != false && !isBlacklisted)
        {
            for (modpack in FlxModding.modpacks.getModpacks(ACTIVE))
            {
                var modpackDirectory:String = modpack.getDirectory();

                if (FlxFileSystem.exists(modpackDirectory + "/" + id))
                {
                    var appendDirectory:String = modpackDirectory + "/" + FlxStringHelper.DEFAULT_APPEND_PREFIX;
                    var mergeDirectory:String = modpackDirectory + "/" + FlxStringHelper.DEFAULT_MERGE_PREFIX;
                    var sourceDirectory:String = modpackDirectory + "/" + FlxScriptUtil.DEFAULT_SOURCE_PREFIX;

                    if (FlxFileSystem.exists(appendDirectory + "/" + id)) 
                        return appendDirectory + "/" + id;

                    if (FlxFileSystem.exists(mergeDirectory + "/" + id)) 
                        return mergeDirectory + "/" + id;

                    if (FlxFileSystem.exists(sourceDirectory + "/" + id)) 
                        return sourceDirectory + "/" + id;

                    return modpackDirectory + "/" + id;
                }
            }
        }

        if (baseDirectory.length != 0)
            return baseDirectory + "/" + id;

        return id;
    }

    /**
     * Registers a new modpack class in the global modpack registry.
     *
     * Modpack classes define how a modpack behaves, including how
     * its metadata is structured, loaded, and interpreted by the
     * modding system.
     *
     * Once registered, the class becomes available to the mod loader
     * and can be instantiated when compatible modpack metadata is
     * discovered during scanning.
     *
     * Multiple modpack classes may be registered at the same time,
     * allowing the engine to support different mod formats.
     *
     * @param modpackClass The modpack class to register.
     */
    public function registerModpackClass(modpackClass:Class<FlxBaseModpack>):Void
    {
        this.modpackClasses.push(modpackClass);
    }

    /**
     * Unregisters a modpack class from the global modpack registry.
     *
     * Once removed, the modding system will no longer recognize or
     * instantiate this modpack type during mod discovery.
     *
     * This can be useful when reloading mod systems, disabling
     * specific mod formats, or cleaning up dynamically loaded
     * modpack implementations.
     *
     * @param modpackClass The modpack class to remove from the registry.
     */
    public function unregisterModpackClass(modpackClass:Class<FlxBaseModpack>):Void
    {
        if (this.modpackClasses.contains(modpackClass))
            this.modpackClasses.remove(modpackClass);
    }

    /**
     * Checks whether the specified modpack class is registered in this registry.
     *
     * This function verifies if the provided `FlxBaseModpack` class reference
     * exists inside the internal `modpackClasses` collection. It is typically
     * used to prevent duplicate registrations or to confirm that a modpack
     * implementation has already been added to the registry.
     *
     * @param modpackClass The modpack class to check for within the registry.
     * @return `true` if the class is already registered, `false` otherwise.
     */
    public function hasModpackClass(modpackClass:Class<FlxBaseModpack>):Bool
    {
        return this.modpackClasses.contains(modpackClass);
    }

    /**
     * Returns all currently registered modpack classes.
     *
     * The returned array represents the internal registry used by
     * the modding system to determine which modpack formats are
     * supported during mod discovery and loading.
     *
     * @return An array containing every registered modpack class.
     */
    public function listModpackClasses():Array<Class<FlxBaseModpack>>
    {
        return this.modpackClasses;
    }

    /**
     * Adds a directory to the global blacklist.
     *
     * Blacklisted directories are ignored by the mod loading system.
     * Any assets or content inside these folders will not be scanned,
     * indexed, or loaded during runtime.
     *
     * This affects all future mod discovery operations until the
     * directory is manually removed from the blacklist.
     *
     * @param directory The directory name or path to blacklist.
     */
    public function addBlacklistedDirectory(directory:String):Void
    {
        this.blacklistedDirectorys.push(directory);    
    }

    /**
     * Removes a directory from the global blacklist.
     *
     * If the directory exists in the blacklist, it will be removed
     * and allowed to participate in future mod discovery scans.
     *
     * If the directory is not currently blacklisted, this function
     * performs no action.
     *
     * @param directory The directory name or path to remove from the blacklist.
     */
    public function removeBlacklistedDirectory(directory:String):Void
    {
        if (this.blacklistedDirectorys.contains(directory))
            this.blacklistedDirectorys.remove(directory);    
    }

    /**
     * Checks whether the given identifier matches a blacklisted directory.
     *
     * This performs a prefix comparison against all registered blacklisted
     * directories. If the provided id begins with any blacklisted directory
     * path, the function returns true.
     *
     * If no custom blacklist entries match, a fallback check is performed
     * against the default Flixel directory to prevent core engine assets
     * from being treated as mod content.
     *
     * @param id The identifier or path to test against the blacklist.
     * @return True if the id is considered blacklisted, otherwise false.
     */
    public function hasBlacklistedDirectory(id:String):Bool
    {
        if (this.listBlacklistedDirectorys().contains(id))
            return true;

        for (directory in this.listBlacklistedDirectorys())
        {
            if (StringTools.startsWith(id, directory))
                return true;
        }

        return StringTools.startsWith(id, FlxModding.FLIXEL_DIRECTORY);
    }

    /**
     * Returns a list of all currently blacklisted directories.
     *
     * This function provides a combined list containing both the user-defined
     * blacklisted directories stored in `blacklistedDirectorys` and the
     * internal Flixel directory used by the modding system.
     *
     * The Flixel directory is always appended to the returned array to ensure
     * that core engine assets are excluded from mod scanning and discovery.
     * This prevents mods from accidentally overriding or interacting with
     * internal framework resources.
     *
     * @return An array containing all directories that are currently blacklisted.
     */
    public function listBlacklistedDirectorys():Array<String>
    {
        return this.blacklistedDirectorys.concat(['${FlxModding.FLIXEL_DIRECTORY}/']);
    }

    /**
     * Registers each default asset library as a modded one
     */
    private function rebuildAssetLibrarys():Void
    {   
        @:privateAccess
        for (libraryName in Assets.libraries.keys())
        {
            Assets.registerLibrary(libraryName, FlxAssetLibrary.fromAssetLibrary(Assets.getLibrary(libraryName)));
            FlxModding.log('Registering Asset Library: "${libraryName}"');
        }
    }

    /**
     * Creates and attaches a GitHub version label to the Flixel debugger.
     */
    private function buildGithubLabel():Void
    {
        #if ((FLX_MODDING_LINK || !FLX_NO_MODDING_LINK) && FLX_DEBUG)
        var label = new TextField();
		label.height = 20;
		label.selectable = false;
		label.y = -9;
		label.multiline = false;
		label.embedFonts = true;
		label.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEBUGGER, 12, 0xffffff);
		label.autoSize = TextFieldAutoSize.LEFT;
		label.text = Std.string("FlxModding " + FlxModding.VERSION);

        FlxG.signals.postGameStart.addOnce(() -> 
        {
            FlxG.debugger.addButton(LEFT, null, () -> FlxG.openURL(FlxModding.GITHUB_LINK)).addChild(label);
        });
        #end
    }

    /**
     * Registers FlxModding-related debug commands in the Flixel console.
     *
     * These commands are primarily intended for debugging and testing mod behavior
     * without restarting the game.
     */
    private function buildDebugCommands():Void
    {
        #if FLX_DEBUG
        FlxG.signals.postGameStart.addOnce(() -> 
        {
            FlxG.console.registerClass(FlxModding);

            FlxG.console.registerFunction("listMods", () -> 
            {
                FlxModding.sort();

                for (modpack in modpacks)
                {
                    FlxG.log.add(modpack.toString());
                }
            });
        });
        #end
    }

    /**
     * Logs a message to the Flixel debugger log.
     *
     * This is a gated helper around `FlxG.log.add` that only outputs when:
     * - FlxModding debug mode is enabled
     * - The build is compiled with FLX_DEBUG
     *
     * @param data Any value to log
     */
    private static function log(data:Dynamic):Void
    {
        if (FlxModding.debug)
        {
            #if FLX_DEBUG
            FlxG.log.add(data);
            #end
        }
    }

    /**
     * Logs a warning message to the Flixel debugger log.
     *
     * Unlike `log`, this does not depend on FlxModding's debug flag,
     * but still requires a FLX_DEBUG build.
     *
     * @param data Any value to log as a warning
     */
    private static function warn(data:Dynamic):Void
    {
        #if FLX_DEBUG
        FlxG.log.warn(data);
        #end
    }

    /**
     * Logs an error message to the Flixel debugger log.
     *
     * This is a thin wrapper around `FlxG.log.error` and is only
     * active in FLX_DEBUG builds.
     *
     * @param data Any value to log as an error
     */
    private static function error(data:Dynamic):Void
    {
        #if FLX_DEBUG
        FlxG.log.error(data);
        #end
    }

    /**
     * Configures the FlxModding system to integrate with Polymod.
     *
     * This function synchronizes several configuration values between
     * the FlxModding runtime and the active Polymod configuration.
     * It ensures that directories ignored by Polymod are also ignored
     * by the FlxModding discovery system, and that Polymod’s script
     * file extensions are recognized by the scripting utilities.
     *
     * The following adjustments are applied:
     * - Adds Polymod's ignored files/directories to the FlxModding blacklist.
     * - Registers the Polymod script file extension if it is not already supported.
     * - Registers the Polymod script class extension for module loading.
     *
     * This function is only compiled when the `polymod` flag is enabled.
     */
    private static function configureWithPolymod()
    {
        #if polymod
        FlxModding.log("Attempting to Configure with Polymod...");
        FlxModding.system.blacklistedDirectorys = FlxModding.system.blacklistedDirectorys.concat(polymod.PolymodConfig.modIgnoreFiles);

        if (!FlxScriptUtil.SCRIPT_FILE_EXTS.contains(polymod.PolymodConfig.scriptExt)) 
            FlxScriptUtil.SCRIPT_FILE_EXTS.push(polymod.PolymodConfig.scriptExt);

        if (!FlxScriptUtil.MODULE_FILE_EXTS.contains(polymod.PolymodConfig.scriptClassExt)) 
            FlxScriptUtil.SCRIPT_FILE_EXTS.push(polymod.PolymodConfig.scriptClassExt);

        FlxModding.log("Polymod Configured!");
        #else
        FlxModding.warn("Failed to Configure with Polymod, Polymod is not installed.");
        #end
    }

    /**
     * Builds and installs the custom mod-aware asset system.
     *
     * This replaces Flixel's default asset accessors with OpenFL-backed
     * implementations that are aware of modded assets.
     *
     * Behavior:
     * - Initializes mod asset libraries
     * - Replaces OpenFL's asset cache with a mod-compatible cache
     * - Overrides FlxG asset accessors to route through openfl.utils.Assets
     */
    private static function buildAssetSystem():Void
    {
        system.rebuildAssetLibrarys();
        openfl.utils.Assets.cache = FlxAssetCache.openFlCache;
        lime.utils.Assets.cache = FlxAssetCache.limeCache;

        #if (FLX_BUILD_SCRIPTS || !FLX_NO_BUILD_SCRIPTS)
        FlxScriptUtil.buildAllScripts();
        FlxScriptUtil.buildAllScriptModules();
        #end

        #if (flixel >= "5.9.0" && FLX_CUSTOM_ASSETS_DIRECTORY)
        FlxG.assets.list = (?type) -> {return openfl.utils.Assets.list(type.toOpenFlType());};
        FlxG.assets.exists = (id, ?type) -> {return openfl.utils.Assets.exists(id, type.toOpenFlType());};
        FlxG.assets.isLocal = (id, ?type, ?useCache) -> {return openfl.utils.Assets.isLocal(id, type.toOpenFlType(), useCache);};

        FlxG.assets.getAssetUnsafe = (id, type, ?useCache) -> 
        {
            switch(type)
            {
                case TEXT: return openfl.utils.Assets.getText(id);
                case BINARY: return openfl.utils.Assets.getBytes(id);
                case IMAGE: return openfl.utils.Assets.getBitmapData(id, useCache);
                case SOUND: return openfl.utils.Assets.getSound(id, useCache);
                case FONT: return openfl.utils.Assets.getFont(id, useCache);
            }
        };

        FlxG.assets.loadAsset = (id, type, ?useCache) -> 
        {
            switch(type)
            {
                case TEXT: return openfl.utils.Assets.loadText(id);
                case BINARY: return openfl.utils.Assets.loadBytes(id);
                case IMAGE: return openfl.utils.Assets.loadBitmapData(id, useCache);
                case SOUND: return openfl.utils.Assets.loadSound(id, useCache);
                case FONT: return openfl.utils.Assets.loadFont(id, useCache);
            }
        };
        #end
    }

    /**
     * Builds and initializes the mod-aware virtual file system.
     */
    private static function buildFileSystem():Void
    {
        #if !sys
        @:privateAccess FlxFileSystem.createVirtualFileSystem();
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
	public var onModAdded:FlxTypedSignal<FlxBaseModpack->Void> = new FlxTypedSignal<FlxBaseModpack->Void>();

	/**
	 * Fires when a modpack is removed from the system.
	 * Useful for cleaning up resources tied to that mod.
	 * Passes the removed FlxBaseModpack.
	 */
	public var onModRemoved:FlxTypedSignal<FlxBaseModpack->Void> = new FlxTypedSignal<FlxBaseModpack->Void>();

	/**
	 * Fires when all modpacks are cleared from the system at once.
	 * Can be used to reset state, release resources, or reinitialize systems
	 * that depend on active mods.
	 */
	public var onModsCleared:FlxSignal = new FlxSignal();

    /**
     * Signal dispatched when a mod gets activated.
     */
    public var onModActived:FlxTypedSignal<FlxBaseModpack->Void> = new FlxTypedSignal<FlxBaseModpack->Void>();

    /** 
     * Signal dispatched when a mod gets deactivated. 
     */
    public var onModDeactived:FlxTypedSignal<FlxBaseModpack->Void> = new FlxTypedSignal<FlxBaseModpack->Void>();

    public function new() {}
}