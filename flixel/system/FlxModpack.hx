package flixel.system;

import flixel.system.FlxMetadataFormat.CreditFormat;
import flixel.util.FlxStringUtil;

/**
 * A specialized modpack class designed to work with the FlxModding system.
 * It uses the FlxMetadataFormat to handle metadata reading and parsing,
 * ensuring that modpacks follow the structure and requirements expected by FlxModding.
 */
class FlxModpack extends FlxBaseModpack<FlxMetadataFormat>
{
	/**
	 * The display name of the modpack.
	 * This is what players will see in the mod menu, credits, or any other UI elements referencing the mod.
	 * It should be a human-readable title like "Cool Mod" rather than a technical ID.
	 */
	public var name:String;

	/**
	 * The version string for the modpack.
	 * Typically formatted like "1.0.0", "1.2.3-beta", etc.
	 */
	public var version:String;

	/**
	 * A short description of the modpack, usually one or two sentences.
	 * This is often shown in mod browsers or detail views to summarize what the mod does or contains.
	 */
	public var description:String;

	/**
	 * An array of credit entries tied to the modpack.
	 * Each credit entry contains contributor names, roles, and optionally contact or link info.
	 * Used to populate credits screens or author listings.
	 */
	public var credits:Array<CreditFormat>;

	public function new(file:String)
	{
		type = FLIXEL;
		super(file, new FlxMetadataFormat());
	}

	override public function updateMetadata(?saveToDisk:Bool = true):Void
	{
		metadata.name = name;
		metadata.version = version;
		metadata.description = description;

		metadata.credits = credits;

		metadata.active = active;
		metadata.priority = ID;

		if (saveToDisk != false)
		{
			FlxModding.system.fileSystem.setFileContent(metaDirectory(), metadata.toJsonString());
		}
	}

    override public function destroy():Void
    {
		name = null;
		version = null;
		description = null;

		credits = null;

        super.destroy();
    }

	override public function fromMetadata(metadata:FlxMetadataFormat):FlxBaseModpack<FlxMetadataFormat>
	{
        this.type = FLIXEL;
		this.metadata = metadata;

		this.name = metadata.name;
		this.version = metadata.version;
		this.description = metadata.description;

		this.credits = metadata.credits;

		this.active = metadata.active;
		this.ID = metadata.priority;

		return this;
	}
}