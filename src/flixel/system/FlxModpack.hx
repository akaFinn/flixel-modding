package flixel.system;

import flixel.system.FlxMetadataFormat.FlxCreditFormat;
import flixel.system.FlxMetadataFormat.FlxLegacyMetadataFormat;
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
	 * The display prefix of the modpack.
	 */
	public var prefix:String;

	/**
	 * The version string for the modpack.
	 */
	public var version:String;

	/**
	 * A short description of the modpack, usually one or two sentences.
	 */
	public var description:String;

	/**
	 * The version string for the modpack.
	 */
	public var api:String;

	/**
	 * An array of credit entries tied to the modpack.
	 */
	public var credits:Array<FlxCreditFormat>;

	/**
	 * An array of tags tied to the modpack.
	 */
	public var tags:Array<String>;

	/**
	 * An array of link entries tied to the modpack.
	 */
	public var links:Array<FlxLinkInstance>;

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
		this.metadata = metadata;

		this.name = metadata.name;
		this.prefix = metadata.prefix;

		this.api = metadata.api;
		this.tags = metadata.tags;
		this.description = metadata.description;
		this.version = metadata.version;

		this.credits = metadata.credits;

		this.ID = metadata.priority;
		this.active = metadata.enabled;
		this.links = metadata.links;

		return this;
	}
}

@:buildModpack(FlxLegacyMetadataFormat)
class FlxLegacyModpack extends FlxBaseModpack<FlxLegacyMetadataFormat>
{
	public var name:String;

	public var version:String;

	public var description:String;

	public var credits:Array<FlxLegacyCreditFormat>;

    override public function destroy():Void
    {
		name = null;
		version = null;
		description = null;

		credits = null;

        super.destroy();
    }

	override public function fromMetadata(metadata:FlxLegacyMetadataFormat):FlxBaseModpack<FlxLegacyMetadataFormat>
	{
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