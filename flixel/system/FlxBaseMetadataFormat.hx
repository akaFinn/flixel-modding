package flixel.system;

/**
 * Basic metadata format representation used by FlxModding.
 * Defines the core structure for storing and converting modpack metadata,
 * acting as a base class that can be extended for custom formats.
 */
class FlxBaseMetadataFormat
{
    /** 
	 * Creates a new metadata format with paths and an optional format override.
	*/
    public function new() {}

    /**
     * Converts this metadata format into a JSON string.
     * The base implementation simply returns an empty string — override to customize output.
     */
	public function toJsonString():String
    {
        return "";
    }

	/** 
	 * Parses Dynamic data into this metadata format. Currently returns itself without modification.
	*/
    public function fromDynamicData(data:Dynamic):FlxBaseMetadataFormat
    {
        return this;
    }
}