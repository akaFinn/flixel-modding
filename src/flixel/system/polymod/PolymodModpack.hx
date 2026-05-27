package flixel.system.polymod;

import haxe.format.JsonHelp;
import haxe.semver.Version;
import flixel.system.format.FlxLicense;

/**
 * A specialized modpack class designed to work with the Polymod system.
 * 
 * This implementation follows Polymod's expected metadata structure,
 * allowing mod information to be parsed and mapped into strongly-typed fields
 * used by the FlxModding ecosystem.
 * 
 * The `@:buildModpack` macro resolves the metadata and icon file at compile time,
 * using either default filenames or Polymod's configured values (when available).
 * 
 * This class is responsible for:
 * - Storing parsed Polymod metadata
 * - Providing convenient access to common fields
 * - Bridging Polymod metadata into the shared `FlxBaseModpack` pipeline
 */
#if !polymod
@:buildModpack("_polymod_meta.json", "_polymod_icon.png")
#else
@:buildModpack(polymod.PolymodConfig.modMetadataFile, polymod.PolymodConfig.modIconFile)
#end
class PolymodModpack extends FlxBaseModpack
{
	/**
	 * The id of the modpack.
	 */
	public var id:String;

	/**
	 * The display title of the modpack.
	 * 
	 * Typically shown in mod menus or selection screens.
	 */
	public var title:String;

	/**
	 * The main author or creator of the modpack.
	 * 
	 * Typically a single person or team name responsible
	 * for the modpack's creation. May be displayed in mod menus
	 * or metadata listings.
	 */
	public var author:String;

	/**
	 * The homepage URL associated with the modpack.
	 * 
	 * Usually links to a repository, website, or mod page.
	 */
	public var homepage:String;

	/**
	 * A short description of the modpack.
	 * 
	 * Generally one or two sentences summarizing the mod.
	 */
	public var description:String;

	/**
	 * An array of contributor entries tied to the modpack.
	 * 
	 * Each contributor includes a name, role, and optional URL.
	 */
	public var contributors:Array<PolymodCreditFormat>;

	/**
	 * The mod version string defined by the modpack.
	 */
	public var modVersion:Version;

	/**
	 * The api version string defined by the modpack.
	 */
	public var apiVersion:Version;

	/**
	 * Raw dynamic metadata associated with the modpack.
	 * 
	 * Contains all unprocessed Polymod metadata fields
	 * not otherwise mapped to explicit class properties.
	 * Can be used for advanced queries, custom fields,
	 * or future extensions without modifying the class structure.
	 */
	public var metadata:Dynamic;

	/**
	 * The license associated with the modpack.
	 */
	public var license:FlxLicense;

	/**
	 * Opens the modpack's homepage in the user's default browser.
	 * 
	 * If `homepage` is null or invalid, behavior depends on
	 * the underlying platform's URL handling.
	 */
	public function openHomepage():Void
	{
		FlxG.openURL(homepage);	
	}

	/**
	 * Populates this modpack using raw dynamic Polymod metadata.
	 * 
	 * Maps Polymod's metadata fields into strongly-typed
	 * class properties. Expected keys include:
	 * - id
	 * - title
	 * - description
	 * - homepage
	 * - contributors
	 * - mod_version
	 * - license
	 * 
	 * @param   meta   Raw metadata object typically parsed from Polymod JSON
	 * 
	 * @return  This modpack instance (for chaining or compatibility)
	 */
	override public function fromDynamic(data:Dynamic):FlxBaseModpack
	{
		this.id = JsonHelp.getFieldString(data, "id", fileName);
		this.title = JsonHelp.getFieldString(data, "title", "Unknown");
		this.description = JsonHelp.getFieldString(data, "description", "");
		this.author = JsonHelp.getFieldString(data, "author", "");

		this.contributors = JsonHelp.getField(data, "contributors", []);
		this.homepage = JsonHelp.getFieldString(data, "homepage", "");

		this.modVersion = Version.fromString(JsonHelp.getFieldString(data, "mod_version", "1.0.0"));
		this.apiVersion = Version.fromString(JsonHelp.getFieldString(data, "api_version", FlxModding.VERSION.toString()));
		this.metadata = JsonHelp.getField(data, "metadata");

		this.license = FlxLicense.getFromName(JsonHelp.getFieldString(data, "license", "The Unlicense"));

		return super.fromDynamic(data);
	}
}

/**
 * Defines the structure for a contributor entry in a Polymod modpack.
 * 
 * Each contributor contains:
 * - A name
 * - Their role in the project
 * - A related URL (e.g. profile or portfolio)
 */
typedef PolymodCreditFormat = 
{
    var name:String;
    var role:String;
    var url:String;
}