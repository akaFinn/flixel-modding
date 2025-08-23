package flixel.system.polymod;

import flixel.system.FlxBaseModpack.FlxBaseMetadataFormat;
import flixel.util.FlxStringUtil;

/**
 * A specialized modpack class designed to work with the Polymod system.
 * It uses the PolymodMetadataFormat to handle metadata reading and parsing,
 * ensuring that modpacks follow the structure and requirements expected by Polymod.
 */
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

    public function new(file:String)
    {
        type = POLYMOD;
        super(file, new PolymodMetadataFormat());
    }

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

	override public function metaDirectory():String
	{
		return directory() + "/" + PolymodMetadataFormat.metaPath;
	}

	override public function iconDirectory():String
	{
		return directory() + "/" + PolymodMetadataFormat.iconPath;
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

class PolymodMetadataFormat extends FlxBaseMetadataFormat
{
    public var title:String;
    public var description:String;
	public var homepage:String;

    public var contributors:Array<PolymodCreditFormat> = [];

	public var api_version:String;
	public var mod_version:String;
	public var license:String;

	public static final metaPath:String = "_polymod_meta.json";
    public static final iconPath:String = "_polymod_icon.png";

    public function new()
    {
        super();
    }

	override public function toJsonString():String
	{
		var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"title": "' + this.title + '",\n');
        buf.add('\t"description": "' + this.description + '",\n');
        buf.add('\t"homepage": "' + this.homepage + '",\n');
        buf.add('\n\t"contributors": [\n');

        for (index in 0...this.contributors.length) 
        {
            var contributor = this.contributors[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + contributor.name + '",\n');
            buf.add('\t\t\t"role": "' + contributor.role + '",\n');
            buf.add('\t\t\t"url": "' + contributor.url + '"\n');
            buf.add('\t\t}');

            if (index < this.contributors.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"api_version": "' + this.api_version + '",\n');
        buf.add('\t"mod_version": "' + this.mod_version + '",\n');
		buf.add('\t"license": "' + this.license + '"\n');
        buf.add('}');

        return buf.toString();
	}

	override public function fromDynamicData(data:Dynamic):PolymodMetadataFormat
    {
		this.title = data.title;
        this.description = data.description;
		this.homepage = data.homepage;

        this.contributors = data.contributors;

		this.api_version = data.api_version;
		this.mod_version = data.mod_version;
		this.license = data.license;

        return this;
    }
}

typedef PolymodCreditFormat = 
{
    var name:String;
    var role:String;
    var url:String;
}