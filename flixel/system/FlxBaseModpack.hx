package flixel.system;

import flixel.system.FlxMetadataFormat.FlxLegacyMetadataFormat;
import flixel.system.polymod.PolymodMetadataFormat;
import flixel.util.FlxStringUtil;
import flixel.util.FlxZipUtil;
import flixel.util.helpers.FlxStringHelper;

/**
 * Represents the different supported types of modpacks in FlxModding.
 * 
 * Each type corresponds to a distinct system or integration method:
 * - FLIXEL: Standard Flixel-style modpacks using the built-in structure.
 * - POLYMOD: Modpacks using the Polymod library for patching/modifying content.
 * - LEGACY: The legacy version type of Flixel modpacks.
 * - CUSTOM: A user-defined or specialized modpack format outside the defaults.
 */
enum FlxModpackType
{
    FLIXEL;
    POLYMOD;
	LEGACY;
    CUSTOM;
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
	 * The type of modpack (Flixel, Polymod, Legacy, or Custom).
	 * Determines how the system treats this mod when loading metadata, assets, or icons.
	 * You can use this to handle legacy mods or introduce entirely new mod formats.
	 */
	public var type:FlxModpackType;

	/**
	 * The metadata information for this modpack.
	 * Stores details such as name, version, description, and other fields
	 * defined by the chosen metadata format (Flixel, Polymod, Legacy, or custom).
	 * This allows the system to interpret and organize mods consistently
	 * across different formats.
	 */
	public var metadata:MetaFormat;

	public var config:Dynamic = null;

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

		switch (metadata)
		{
			case FlxMetadataFormat: this.type = FLIXEL;
			case PolymodMetadataFormat: this.type = POLYMOD;
			case FlxLegacyMetadataFormat: this.type = LEGACY;
			default: this.type = CUSTOM;
		}

		super();

		this.ID = 0;
		
		if (FlxG.assets.exists(configDirectory()))
		{
			this.config = FlxStringHelper.parseJsonString(FlxG.assets.getText(configDirectory()));
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
		else
		{
			FlxG.log.warn("Failed to locate config directory, config file path has not been setup via metadata macro.");
			return "";
		}
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
		metadata = null;

		type = null;
		file = null;

        super.destroy();   
    }

    override public function toString():String
    {
        return FlxStringUtil.getDebugString([
			LabelValuePair.weak("class", Type.getClassName(Type.getClass(this)).split(".").pop()),
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