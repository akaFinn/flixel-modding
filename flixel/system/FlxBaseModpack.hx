package flixel.system;

import flixel.system.FlxMetadataFormat.FlxLegacyMetadataFormat;
import flixel.system.polymod.PolymodMetadataFormat;
import flixel.util.FlxStringUtil;
import flixel.util.FlxZipUtil;
import flixel.util.helpers.FlxStringHelper;
import haxe.Ini;

/**
 * Defines a single mod package entry used by the modding system.
 * 
 * Each `FlxModPackage` represents a specific modpack configuration,
 * including its name, the base modpack class it uses, and the metadata
 * format class associated with it.
 */
typedef FlxModPackage =
{
	var name:String; // The unique name identifier for the mod package
	var cls:Class<FlxBaseModpack<Dynamic>>; // Reference to the core modpack class used to handle loading and functionality
	var meta:Class<FlxBaseMetadataFormat>; // Reference to the metadata format class that defines how mod info is structured
}

/**
 * Base representation of a modpack within FlxModding.
 * Holds all core metadata, file paths, and other properties
 * used to manage and identify a mod at runtime.
 * 
 * This class serves as the foundation for all modpack types (Flixel, Polymod, Legacy, or custom),
 * providing shared variables and basic setup behavior that specialized modpack
 * classes can build upon.
 */
@:access(flixel.system.FlxModding)
@:autoBuild(flixel.util.FlxModUtil.buildModpack())
class FlxBaseModpack<MetaFormat:FlxBaseMetadataFormat> extends FlxBasic
{
	/**
	 * The metadata information for this modpack.
	 * Stores details such as name, version, description, and other fields
	 * defined by the chosen metadata format (Flixel, Polymod, Legacy, or custom).
	 * This allows the system to interpret and organize mods consistently
	 * across different formats.
	 */
	public var metadata:MetaFormat;

	/**
	 * Stores a custom INI configuration for this modpack.
	 * Can be used to store and retrieve custom data/settings specific to this mod.
	 */
	public var config:Ini;

	/**
	 * The file path to the modpack archive or directory.
	 * Used internally for locating and loading the modpack’s data.
	 */
	var file:String;

	/**
	 * Creates a new modpack instance using the specified folder name.
	 * Also auto-assigns an internal ID and default priority based on how many modpacks exist at creation time.
	 * The `file` parameter is expected to be the folder name (not a full path).
	 */
	public function new(file:String, metadata:Class<MetaFormat>)
	{
		this.file = file;
		this.metadata = Type.createInstance(metadata, []);

		super();

		this.ID = 0;
		
		if (FlxG.assets.exists(configDirectory()))
		{
			this.config = FlxStringHelper.parseIniString(FlxG.assets.getText(configDirectory()));
		}
	}

	/**
	 * Returns the full directory path of this modpack.
	 * Combines the global mods directory with this mod’s folder name.
	 */
	public function directory():String
	{
		return FlxModding.modsDirectory + "/" + file;
	}

	/**
	 * Returns the directory path where this modpack's metadata is stored.
	 */
	public function metaDirectory():String
	{
		return directory() + "/" + Reflect.field(Type.getClass(metadata), "metaPath");
	}

	/**
	 * Returns the directory path where the modpack's icon is located.
	 */
	public function iconDirectory():String
	{
		return directory() + "/" + Reflect.field(Type.getClass(metadata), "iconPath");
	}

	/**
	 * Returns the directory path where the modpack's config file is located.
	 * Only returns a valid directory if the config file path is setup via macro.
	 */
	public function configDirectory():String
	{
		if (Reflect.hasField(Type.getClass(metadata), "configPath"))
		{
			return directory() + "/" + Reflect.field(Type.getClass(metadata), "configPath");
		}
		
		return directory() + "/_unknown_config_file_name.ini";
	}


	/**
	 * Saves the modpack’s runtime data back to the metadata.
	 * Function is designed and made to be overridden.
	 * 
	 * @param   saveToDisk (Optional) Takes the runtime metadata
	 * 	                   and saves it to the metadata file located on the disk.
	 */
	public function updateMetadata(?saveToDisk:Bool = true):Void {}

	/**
	 * Loads this modpack's values from a loaded metadata format.
	 */
	public function fromMetadata(metadata:MetaFormat):FlxBaseModpack<MetaFormat>
	{
		return this;
	}

	/**
     * Converts this modpack runtime data into a JSON string.
     * The base implementation simply returns an empty string — override to customize output.
     */
	public function toJsonString():String
    {
        return "";
    }

	/**
	 * Returns the total size of the modpack in bytes.
	 * Includes all files and subfolders contained within.
	 */
	public function getModpackSize():Int
	{
		#if sys
		function getSysFolderSize(path:String):Int
		{
			var total:Int = 0;

			if (!sys.FileSystem.exists(path) || !sys.FileSystem.isDirectory(path)) return 0;

			for (entry in sys.FileSystem.readDirectory(path))
        	{
				var fullPath = sys.FileSystem.fullPath(path + "/" + entry);

				if (sys.FileSystem.isDirectory(fullPath))
            	{
					total += getSysFolderSize(fullPath);
				}
            	else
            	{
					total += sys.FileSystem.stat(fullPath).size;
				}
			}

			return total;
		}

		return getSysFolderSize(directory());
		#else
		return 0;
		#end
	}

	override public function destroy():Void
    {
		file = null;
		metadata = null;

		config = null;

        super.destroy();   
    }

    override public function toString():String
    {
        return FlxStringUtil.getDebugString([
			LabelValuePair.weak("class", Type.getClassName(Type.getClass(this))),
			LabelValuePair.weak("path", directory()),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("size", FlxStringUtil.formatBytes(getModpackSize()))
		]);
    }

	override function set_active(Value:Bool):Bool
	{
		active = Value;

		if (Value != false)
			FlxModding.signals.onModActived.dispatch(cast this);
		else
			FlxModding.signals.onModDeactived.dispatch(cast this);

		return Value;
	}
}