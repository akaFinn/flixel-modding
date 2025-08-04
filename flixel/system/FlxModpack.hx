package flixel.system;

import flixel.system.FlxModding.CreditFormat;
import flixel.system.FlxModding.MetadataFormat;
import flixel.system.FlxModding.PolymodMetadataFormat;
import flixel.util.FlxStringUtil;

#if (!js || !html5)
import sys.io.File;
#end

enum FlxModpackType
{
    FLIXEL;
    POLYMOD;
    CUSTOM;
}

/**
 * Represents a single modpack instance that can be added to FlxModding.
 * Stores mod-related data and initialization behavior.
 */
class FlxModpack extends FlxBasic
{
	/**
	 * The display name of the modpack.
	 * Used for UI, metadata, and identification.
	 */
	public var name:String;

	/**
	 * The version string for the modpack.
	 * Typically formatted like "1.0.0".
	 */
	public var version:String;

	/**
	 * A short description of the modpack.
	 * Useful for menus or listing info about the mod.
	 */
	public var description:String;

	/**
	 * Priority value used for sorting modpacks.
	 * Higher priority mods are loaded later.
	 */
	public var priority:Int;

	/**
	 * The folder name where the modpack is stored.
	 * This name is used for path generation.
	 */
	public var file:String;

	/**
	 * An array of credit entries tied to the modpack.
	 * Each entry contains information about contributors.
	 */
	public var credits:Array<CreditFormat>;

	/**
	 * The type of modpack—Flixel, Polymod, or Custom.
	 * This affects how metadata and icons are handled.
	 */
	public var type:FlxModpackType;

	/**
	 * Creates a new modpack instance using the specified folder name.
	 * Automatically assigns ID and priority based on the current mod count.
	 */
	public function new(file:String)
	{
		this.file = file;
		this.ID = FlxModding.mods.length + 1;
		this.priority = FlxModding.mods.length + 1;

		super();
	}

	/**
	 * Saves the modpack’s metadata back to disk.
	 * Only works for FLIXEL-type modpacks and not on HTML5 targets.
	 */
	public function updateMetadata():Void
	{
		if (type == FLIXEL)
		{
			#if (!js || !html5)
			File.saveContent(metaDirectory(), FlxModpack.toJsonString(
			{
				name: name,
				version: version,
				description: description,

				credits: credits,

				priority: priority,
				active: active,
			}));
			#end
		}
	}

	/**
	 * Loads this modpack's values from a parsed metadata object.
	 * Populates the fields and sets the mod type to FLIXEL.
	 */
	public function loadFromMetadata(metadata:MetadataFormat):FlxModpack
	{
        type = FLIXEL;

		name = metadata.name;
		version = metadata.version;
		description = metadata.description;

		credits = metadata.credits;

		priority = metadata.priority;
		active = metadata.active;

		return this;
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
	 * The path differs depending on the modpack type (Flixel, Polymod, or Custom).
	 */
	public function metaDirectory():String
	{
		@:privateAccess
		{
			switch (type)
			{
				case FLIXEL:
					return directory() + "/" + FlxModding.metaDirectory;
				case POLYMOD:
					return directory() + "/" + FlxModding.metaPolymodDirectory;
				case CUSTOM:
					return directory() + "/" + FlxModding.metaCustomDirectory;
			}
		}  
	}

	/**
	 * Returns the directory path where the modpack's icon is located.
	 * Different mod types use different icon subfolders.
	 */
	public function iconDirectory():String
	{
		@:privateAccess
		{
			switch (type)
			{
				case FLIXEL:
					return directory() + "/" + FlxModding.iconDirectory;
				case POLYMOD:
					return directory() + "/" + FlxModding.iconPolymodDirectory;
				case CUSTOM:
					return directory() + "/" + FlxModding.iconCustomDirectory;
			}
		}  
	}

    override public function destroy():Void
    {
        super.destroy();
        FlxModding.remove(this);    
    }

    override public function toString():String
    {
        return FlxStringUtil.getDebugString([
			LabelValuePair.weak("name", name),
            LabelValuePair.weak("active", active),
            LabelValuePair.weak("alive", alive),
            LabelValuePair.weak("exists", exists)
		]);
    }

    /**
	 * Converts a `MetadataFormat` object into a readable JSON-formatted string.
	 * This is mainly used for saving modpack metadata into a `.json` file.
	 */
	public static function toJsonString(metadata:MetadataFormat):String
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