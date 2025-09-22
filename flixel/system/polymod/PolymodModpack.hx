package flixel.system.polymod;

import flixel.system.polymod.PolymodMetadataFormat.PolymodCreditFormat;
import flixel.util.FlxStringUtil;

/**
 * A specialized modpack class designed to work with the Polymod system.
 * It uses the PolymodMetadataFormat to handle metadata reading and parsing,
 * ensuring that modpacks follow the structure and requirements expected by Polymod.
 */
@:buildModpack(PolymodMetadataFormat)
class PolymodModpack extends FlxBaseModpack<PolymodMetadataFormat>
{
	/**
	 * The display title of the modpack.
	 */
	public var title:String;

	/**
	 * The homepage string for the modpack.
	 */
	public var homepage:String;

	/**
	 * A short description of the modpack, usually one or two sentences.
	 */
	public var description:String;

	/**
	 * An array of contributor entries tied to the modpack.
	 */
	public var contributors:Array<PolymodCreditFormat>;

	/**
	 * The version string for the modpack.
	 */
	public var version:String;

	/**
	 * The license string for the modpack.
	 */
	public var license:String;

	public function openHomepage():Void
	{
		FlxG.openURL(homepage);	
	}

	override public function updateMetadata(?saveToDisk:Bool = true):Void
	{
		metadata.title = title;
		metadata.description = description;
		metadata.homepage = homepage;

		metadata.contributors = contributors;

		metadata.mod_version = version;
		metadata.license = license;

		if (saveToDisk != false)
		{
			FlxModding.system.fileSystem.setFileContent(metaDirectory(), metadata.toJsonString());
		}
	}

	override public function fromMetadata(metadata:PolymodMetadataFormat):FlxBaseModpack<PolymodMetadataFormat>
	{
        this.type = POLYMOD;
		this.metadata = metadata;

		this.title = metadata.title;
		this.description = metadata.description;
		this.homepage = metadata.homepage;

		this.contributors = metadata.contributors;

		this.version = metadata.mod_version;
		this.license = metadata.license;

		return this;
	}
}