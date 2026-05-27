package flixel.system;

import haxe.semver.Version;
import haxe.format.JsonHelp;

/**
 * A legacy modpack implementation designed for older
 * FlxModding metadata formats.
 * 
 * This class exists primarily for backward compatibility,
 * supporting modpacks that rely on the original
 * `metadata.json` structure and simpler credit formatting.
 * 
 * The `@:buildModpack` macro links `metadata.json`
 * and `picture.png` at compile time.
 * 
 * Compared to newer modpack formats, this version:
 * - Uses plain string versions (no semantic version parsing)
 * - Uses a simplified credit structure
 * - Stores minimal metadata fields
 */
@:buildModpack("metadata.json", "picture.png")
class FlxLegacyModpack extends FlxBaseModpack
{
	/** 
	 * The display name of the legacy modpack. 
	 */
	public var name:String;

	/** 
	 * The version string of the legacy modpack. 
	 */
	public var version:Version;

	/** 
	 * A short description of the legacy modpack. 
	 */
	public var description:String;

	/** 
	 * List of contributor entries using the legacy credit format. 
	 */
	public var credits:Array<FlxLegacyCreditFormat>;

	/**
	 * Cleans up this legacy modpack instance and releases references.
	 * 
	 * Clears all metadata fields before delegating to `super.destroy()`
	 * to ensure proper memory cleanup.
	 */
    override public function destroy():Void
    {
		name = null;
		version = null;
		description = null;
		credits = null;

        super.destroy();
    }

	/**
	 * Populates this legacy modpack using raw dynamic metadata.
	 * 
	 * Maps the expected legacy fields directly:
	 * - name
	 * - version
	 * - description
	 * - credits
	 * - active state
	 * - priority (ID)
	 * 
	 * @param   data   Raw metadata object parsed from `metadata.json`
	 * 
	 * @return  This modpack instance (for chaining or compatibility)
	 */
	override public function fromDynamic(data:Dynamic):FlxBaseModpack
	{
		this.name = JsonHelp.getFieldString(data, "name", "Unknown");
		this.version = Version.fromString(JsonHelp.getFieldString(data, "version", "Unknown"));
		this.description = JsonHelp.getFieldString(data, "description", "");

		this.credits = JsonHelp.getField(data, "credits", []);

		this.active = JsonHelp.getFieldBool(data, "active", FlxBaseModpack.defaultActive);
		this.order = JsonHelp.getFieldInt(data, "priority", 0);

		return super.fromDynamic(data);
	}

	/**
	 * Serializes this legacy modpack into a formatted JSON string.
	 * 
	 * Builds the JSON manually using `StringBuf` to preserve
	 * the legacy field ordering and structure expected by
	 * older FlxModding implementations.
	 * 
	 * @return  A JSON string representing this legacy modpack
	 */
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
        buf.add('\n\t"priority": ' + this.order + ',\n');
        buf.add('\t"active": ' + this.active + '\n');
        buf.add('}');

        return buf.toString();
	}
}

/**
 * Defines the structure for a legacy credit entry.
 * 
 * Each credit contains:
 * - A contributor name
 * - Their title or role
 * - A socials string (typically a single link or handle)
 */
typedef FlxLegacyCreditFormat = 
{
    var name:String;
    var title:String;
    var socials:String;
}