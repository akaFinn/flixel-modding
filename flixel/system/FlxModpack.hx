package flixel.system;

import flixel.system.FlxMetadataFormat.CreditFormat;
import flixel.system.FlxMetadataFormat;
import flixel.util.FlxStringUtil;

/**
 * A specialized modpack class designed to work with the FlxModding system.
 * It uses the FlxMetadataFormat to handle metadata reading and parsing,
 * ensuring that modpacks follow the structure and requirements expected by FlxModding.
 */
@:buildModpack(FlxMetadataFormat)
class FlxModpack extends FlxBaseModpack<FlxMetadataFormat>
{
	/**
	 * The display name of the modpack.
	 */
	public var name:String;

	/**
	 * The version string for the modpack.
	 */
	public var version:String;

	/**
	 * A short description of the modpack, usually one or two sentences.
	 */
	public var description:String;

	/**
	 * An array of credit entries tied to the modpack.
	 */
	public var credits:Array<CreditFormat>;

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