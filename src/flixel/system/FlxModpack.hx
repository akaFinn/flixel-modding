package flixel.system;

import haxe.format.JsonHelp;
import haxe.semver.Version;
import flixel.system.format.FlxLicense;

/**
 * A specialized modpack class designed to work with the FlxModding system.
 * 
 * It uses a metadata format tailored specifically for flixel-modding,
 * allowing automatic metadata parsing, validation, and serialization.
 * 
 * The `@:buildModpack` macro reads `_metadata.json` and `_icon.png`
 * at compile time, wiring the modpack into the FlxModding pipeline.
 * 
 * This class is responsible for:
 * - Storing parsed mod metadata
 * - Converting metadata to strongly-typed fields
 * - Serializing modpack data back into JSON format
 */
@:buildModpack("_metadata.json", "_icon.png")
class FlxModpack extends FlxBaseModpack
{
	/** 
	 * Display name of the modpack. 
	 */
	public var name:String;

	/** 
	 * Short identifier prefix used for namespacing assets or content. 
	 */
	public var prefix:String;

	/** 
	 * Semantic version of the modpack itself. 
	 */
	public var version:Version;

	/** 
	 * Human-readable description of the modpack. 
	 */
	public var description:String;

	/** 
	 * Target FlxModding API version required by this modpack. 
	 */
	public var api:Version;

	/** 
	 * List of contributors and their associated roles. 
	 */
	public var credits:Array<FlxCreditFormat>;

	/** 
	 * Optional descriptive tags used for categorization. 
	*/
	public var tags:Array<String>;

	/** 
	 * General-purpose links related to the modpack (e.g. homepage, repository). 
	 */
	public var links:Array<FlxLinkDefinition>;

	/**
	 * The license associated with the modpack.
	 */
	public var license:FlxLicense;

	/**
	 * Cleans up this modpack instance and releases references.
	 * 
	 * Clears all metadata fields and resets runtime properties
	 * before delegating to `super.destroy()`.
	 * 
	 * This helps ensure proper garbage collection and prevents
	 * stale metadata from persisting in memory.
	 */
    override public function destroy():Void
    {
		this.name = null;
        this.prefix = null;

        this.api = null;
        this.tags = null;
        this.description = null;
		this.version = null;

		this.credits = null;

        this.links = null;
		this.license = null;

        super.destroy();
    }

	/**
	 * Populates this modpack using raw dynamic metadata.
	 * 
	 * Converts loosely-typed JSON data into strongly-typed fields,
	 * including semantic version parsing via `Version.fromString`.
	 * 
	 * The following fields are mapped:
	 * - name, prefix
	 * - api version
	 * - tags and description
	 * - mod version
	 * - credits and links
	 * - priority (order) and enabled state
	 * 
	 * @param   data   Raw metadata object typically parsed from JSON
	 * 
	 * @return  This modpack instance (for chaining or compatibility)
	 */
	override public function fromDynamic(data:Dynamic):FlxBaseModpack
	{
		this.name = JsonHelp.getFieldString(data, "name", "Unknown");
		this.prefix = JsonHelp.getFieldString(data, "prefix", "unknown");

		this.api = Version.fromString(JsonHelp.getFieldString(data, "api", FlxModding.VERSION.toString()));
		this.tags = JsonHelp.getField(data, "tags", []);
		this.description = JsonHelp.getFieldString(data, "description", "");
		this.version = Version.fromString(Std.string(JsonHelp.getFieldString(data, "version", "1.0.0")));

		this.credits = JsonHelp.getField(data, "credits", []);

		this.order = JsonHelp.getFieldInt(data, "priority", 0);
		this.active = JsonHelp.getFieldBool(data, "enabled", FlxBaseModpack.defaultActive);
		this.links = JsonHelp.getField(data, "links", []);

		this.license = FlxLicense.getFromName(JsonHelp.getFieldString(data, "license", "The Unlicense"));

		return super.fromDynamic(data);
	}

	/**
	 * Serializes this modpack into a formatted JSON string.
	 * 
	 * Builds the JSON manually using `StringBuf` to ensure:
	 * - Stable field ordering
	 * - Explicit formatting and indentation
	 * - Controlled handling of nullable arrays
	 * 
	 * Arrays such as `tags`, `credits`, and `links`
	 * are initialized to empty arrays if null to
	 * guarantee valid JSON output.
	 * 
	 * @return  A JSON string representing this modpack
	 */
	override public function toJsonString():String
	{
		var buf:StringBuf = new StringBuf();

        buf.add('{\n'); 

        buf.add('\t"name": "${this.name}",\n');
        buf.add('\t"prefix": "${this.prefix}",\n');

        buf.add('\n\t"api": "${this.api}",\n');

        if (this.tags == null)
			this.tags = [];

        buf.add('\t"tags": [');

        for (index in 0...this.tags.length)
        {
            var tag = this.tags[index];

            buf.add('"' + tag + '"');
            if (index < this.tags.length - 1)
            {
                buf.add(', ');
            }
        }

        buf.add('],\n');

        buf.add('\t"description": "${this.description}",\n');
        buf.add('\t"version": "${this.version.toString()}",\n');

        if (this.credits == null)
			this.credits = [];
	
        buf.add('\n\t"credits": [\n');

        for (index in 0...this.credits.length) 
        {
            var credit = this.credits[index];

            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "${credit.name}",\n');
            buf.add('\t\t\t"role": "${credit.role}",\n');

            buf.add('\t\t\t"links": [');

            for (index in 0...credit.links.length)
            {
                var link = credit.links[index];

                buf.add('{"title": "${link.title}", "url": "${link.url}"}');
                if (index < credit.links.length - 1)
                {
                    buf.add(', ');
                }
            }

            buf.add(']\n');
            
            buf.add('\t\t}');

            if (index < this.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
		
        buf.add('\n\t"priority": ${this.order},\n');
        buf.add('\t"enabled": ${this.active},\n');

        if (this.links == null) 
			this.links = [];

        buf.add('\t"links": [');

        for (index in 0...this.links.length)
        {
            var link = this.links[index];

            buf.add('{"title": "${link.title}", "url": "${link.url}"}');
            if (index < this.links.length - 1)
            {
                buf.add(', ');
            }
        }

        buf.add('],\n');
		buf.add('\n\t"license": "${this.license.name}"\n');
        buf.add('}');

        return buf.toString();
	}
}

/**
 * Defines the structure for a credit entry inside a modpack.
 * 
 * Each credit contains:
 * - A contributor name
 * - Their role in the project
 * - Optional related links (e.g. socials, portfolio)
 */
typedef FlxCreditFormat = 
{
    var name:String;
    var role:String;
    var links:Array<FlxLinkDefinition>;
}

/**
 * Defines a titled URL entry.
 * 
 * Used for both general modpack links and contributor links.
 */
typedef FlxLinkDefinition = 
{
    var title:String;
    var url:String;
}