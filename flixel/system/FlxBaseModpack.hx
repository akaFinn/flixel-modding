package flixel.system;

import flixel.util.FlxStringUtil;
import haxe.Json;

enum FlxModpackType
{
    FLIXEL;
    POLYMOD;
    CUSTOM;
}

/**
 * Base representation of a modpack within FlxModding.
 * Holds all core metadata, file paths, and other properties
 * used to manage and identify a mod at runtime.
 * 
 * This class serves as the foundation for all modpack types (Flixel, Polymod, or custom),
 * providing shared variables and basic setup behavior that specialized modpack
 * classes can build upon.
 */
class FlxBaseModpack<MetaFormat:FlxBaseMetadataFormat> extends FlxBasic
{
	/**
	 * The type of modpack (Flixel, Polymod, or Custom).
	 * Determines how the system treats this mod when loading metadata, assets, or icons.
	 * You can use this to handle legacy mods or introduce entirely new mod formats.
	 */
	public var type:FlxModpackType;

	/**
	 * The metadata information for this modpack.
	 * Stores details such as name, version, description, and other fields
	 * defined by the chosen metadata format (Flixel, Polymod, or custom).
	 * This allows the system to interpret and organize mods consistently
	 * across different formats.
	 */
	public var metadata:MetaFormat;

	var file:String;

	/**
	 * Creates a new modpack instance using the specified folder name.
	 * Also auto-assigns an internal ID and default priority based on how many modpacks exist at creation time.
	 * The `file` parameter is expected to be the folder name (not a full path).
	 */
	public function new(file:String, metadata:MetaFormat)
	{
		this.file = file;
		this.metadata = metadata;

		super();

		this.ID = 0;
	}

	/**
	 * Returns the full directory path of this modpack.
	 * Combines the global mods directory with this mod’s folder name.
	 */
	public function directory():String
	{
		@:privateAccess
		return FlxModding.modsDirectory + "/" + file;
	}

	/**
	 * Returns the directory path where this modpack's metadata is stored.
	 * Function is designed and made to be overridden.
	 */
	public function metaDirectory():String
	{
		return directory() + "/metadata.json";
	}

	/**
	 * Returns the directory path where the modpack's icon is located.
	 * Function is designed and made to be overridden.
	 */
	public function iconDirectory():String
	{
		return directory() + "/picture.png";
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
			LabelValuePair.weak("active", active)
		]);
    }
}

/**
 * Basic metadata format representation used by FlxModding.
 * Defines the core structure for storing and converting modpack metadata,
 * acting as a base class that can be extended for custom formats.
 */
class FlxBaseMetadataFormat
{
    /** 
	 * Creates a new metadata format with paths and an optional format override.
	*/
    public function new() {}

    /**
     * Converts this metadata format into a JSON string.
     * The base implementation simply returns an empty string — override to customize output.
     */
	public function toJsonString():String
    {
        return "";
    }

	/** 
	 * Parses Dynamic data into this metadata format. Currently returns itself without modification.
	*/
    public function fromDynamicData(data:Dynamic):FlxBaseMetadataFormat
    {
        return this;
    }
}