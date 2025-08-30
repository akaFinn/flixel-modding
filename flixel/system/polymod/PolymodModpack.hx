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
	 * This is what players will see in the mod menu, credits, or any other UI elements referencing the mod.
	 * It should be a human-readable title like "Cool Mod" rather than a technical ID.
	 */
	public var title:String;

	/**
	 * The homepage string for the modpack.
	 * Used for kinding more projects created by the creator of the modpack.
	 */
	public var homepage:String;

	/**
	 * A short description of the modpack, usually one or two sentences.
	 * This is often shown in mod browsers or detail views to summarize what the mod does or contains.
	 */
	public var description:String;

	/**
	 * An array of contributor entries tied to the modpack.
	 * Each credit entry contains contributor names, roles, and optionally contact or link info.
	 * Used to populate credits screens or author listings.
	 */
	public var contributors:Array<PolymodCreditFormat>;

	/**
	 * The version string for the modpack.
	 * Typically formatted like "1.0.0", "1.2.3-beta", etc.
	 * This is mainly for display purposes and update tracking—it is not parsed automatically.
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
