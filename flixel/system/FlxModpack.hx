package flixel.system;

import flixel.system.FlxBaseModpack.FlxBaseMetadataFormat;
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

class FlxMetadataFormat extends FlxBaseMetadataFormat
{
    public var name:String;
    public var version:String;
    public var description:String;

    public var credits:Array<CreditFormat> = [];

    public var priority:Int;
    public var active:Bool;

	public static final metaPath:String = "metadata.json";
    public static final iconPath:String = "picture.png";

    public function new()
    {
        super();
    }

	override public function toJsonString():String
	{
		var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"name": "' + this.name + '",\n');
        buf.add('\t"version": "' + this.version + '",\n');
        buf.add('\t"description": "' + this.description + '",\n');
        buf.add('\n\t"credits": [\n');

        for (index in 0...this.credits.length) 
        {
            var credit = this.credits[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + credit.name + '",\n');
            buf.add('\t\t\t"title": "' + credit.title + '",\n');
            buf.add('\t\t\t"socials": "' + credit.socials + '"\n');
            buf.add('\t\t}');

            if (index < this.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"priority": ' + this.priority + ',\n');
        buf.add('\t"active": ' + this.active + '\n');
        buf.add('}');

        return buf.toString();
	}

	override public function fromDynamicData(data:Dynamic):FlxMetadataFormat
    {
		this.name = data.name;
        this.version = data.version;
        this.description = data.description;

        this.credits = data.credits;

        this.priority = data.priority;
        this.active = data.active;

        return this;
    }
}

typedef CreditFormat = 
{
    var name:String;
    var title:String;
    var socials:String;
}