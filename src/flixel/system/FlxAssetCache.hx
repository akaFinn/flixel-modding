package flixel.system;

import openfl.text.Font;
import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.utils.IAssetCache;
import lime.utils.AssetCache;
import lime.utils.AssetType;

/**
 * Global asset cache bridge used by the Flixel modding system.
 *
 * This class exposes two cache implementations used by different
 * parts of the OpenFL/Lime asset pipeline:
 *
 * - `openFlCache` is used by OpenFL's `IAssetCache` interface.
 * - `limeCache` is used internally by Lime's `AssetCache`.
 *
 * Both caches automatically sanitize asset IDs through the
 * modding system before storing or retrieving them. This ensures
 * that asset paths are normalized and safe when mods inject
 * or override assets at runtime.
 *
 * In practice this allows the modding system to intercept asset
 * loading while still using the normal OpenFL/Lime caching layers.
 */
class FlxAssetCache
{
    /**
     * OpenFL asset cache implementation.
     *
     * This cache satisfies the `IAssetCache` interface used by the
     * OpenFL asset system. It stores bitmap, font, and sound assets
     * using sanitized asset paths so that modded content integrates
     * cleanly with OpenFL's asset loading pipeline.
     */
    public static var openFlCache:FlxOpenFlAssetCache = new FlxOpenFlAssetCache();

    /**
     * Lime asset cache implementation.
     *
     * This wraps Lime's `AssetCache` and ensures all asset identifiers
     * are sanitized through the modding system before interacting with
     * the underlying cache. It is primarily used by Lime's asset
     * loading internals.
     */
    public static var limeCache:FlxLimeAssetCache = new FlxLimeAssetCache();
}

private class FlxOpenFlAssetCache implements IAssetCache
{
    var bitmaps:Map<String, BitmapData>;
    var fonts:Map<String, Font>;
    var sounds:Map<String, Sound>;

    public var enabled(get, set):Bool;

    var _enabled:Bool;

    public function new()
    {
        bitmaps = new Map<String, BitmapData>();
        fonts = new Map<String, Font>();
        sounds = new Map<String, Sound>();
    }

    /**
     * Retrieves a cached bitmap asset.
     *
     * The asset ID is sanitized through the modding system before
     * performing the lookup. If the bitmap is not present in the
     * cache, this function returns `null`.
     *
     * @param id The asset identifier used when the bitmap was cached.
     */
    public function getBitmapData(id:String):BitmapData
    {
        return this.bitmaps.get(getPath(id));
    }

    /**
     * Retrieves a cached font asset.
     *
     * The asset ID is sanitized before lookup to ensure modded
     * assets resolve to the correct normalized path.
     *
     * @param id The font asset identifier.
     */
    public function getFont(id:String):Font
    {
        return this.fonts.get(getPath(id));
    }

    /**
     * Retrieves a cached sound asset.
     *
     * The asset ID is normalized through the modding system
     * before accessing the cache.
     *
     * @param id The sound asset identifier.
     */
    public function getSound(id:String):Sound
    {
        return this.sounds.get(getPath(id));
    }

    /**
     * Checks whether a bitmap asset exists in the cache.
     *
     * @param id The bitmap asset identifier.
     */
    public function hasBitmapData(id:String):Bool
    {
        return this.bitmaps.exists(getPath(id));
    }

    /**
     * Checks whether a font asset exists in the cache.
     *
     * @param id The font asset identifier.
     */
    public function hasFont(id:String):Bool
    {
        return this.fonts.exists(getPath(id));
    }

    /**
     * Checks whether a sound asset exists in the cache.
     *
     * @param id The sound asset identifier.
     */
    public function hasSound(id:String):Bool
    {
        return this.sounds.exists(getPath(id));
    }

    /**
     * Removes a bitmap asset from the cache.
     *
     * Returns `true` if the bitmap was present and removed.
     *
     * @param id The bitmap asset identifier.
     */
    public function removeBitmapData(id:String):Bool
    {
        return this.bitmaps.remove(getPath(id));
    }

    /**
     * Removes a font asset from the cache.
     *
     * Returns `true` if the font existed and was removed.
     *
     * @param id The font asset identifier.
     */
    public function removeFont(id:String):Bool
    {
        return this.fonts.remove(getPath(id));
    }

    /**
     * Removes a sound asset from the cache.
     *
     * Returns `true` if the sound existed and was removed.
     *
     * @param id The sound asset identifier.
     */
    public function removeSound(id:String):Bool
    {
        return this.sounds.remove(getPath(id));
    }

    /**
     * Stores a bitmap asset in the cache.
     *
     * The asset ID is sanitized before being stored so that
     * modded asset paths resolve consistently across the
     * engine's asset systems.
     *
     * @param id The bitmap asset identifier.
     * @param bitmapData The bitmap data to store.
     */
    public function setBitmapData(id:String, bitmapData:BitmapData):Void
    {
        this.bitmaps.set(getPath(id), bitmapData);
    }

    /**
     * Stores a font asset in the cache.
     *
     * @param id The font asset identifier.
     * @param font The font instance to cache.
     */
    public function setFont(id:String, font:Font):Void
    {
        this.fonts.set(getPath(id), font);
    }

    /**
     * Stores a sound asset in the cache.
     *
     * @param id The sound asset identifier.
     * @param sound The sound instance to cache.
     */
    public function setSound(id:String, sound:Sound):Void
    {
        this.sounds.set(getPath(id), sound);
    }

    /**
     * Clears cached assets.
     *
     * If a prefix is provided, implementations may choose to only
     * remove assets whose sanitized IDs begin with that prefix.
     * Otherwise the entire cache may be cleared.
     *
     * @param prefix Optional asset path prefix used to filter removals.
     */
    public function clear(?prefix:String)
    {
        prefix = getPath(prefix);

        if (prefix == null)
		{
			bitmaps = new Map<String, BitmapData>();
			fonts = new Map<String, Font>();
			sounds = new Map<String, Sound>();
		}
		else
		{
			var keys = bitmaps.keys();

			for (key in keys)
			{
				if (StringTools.startsWith(key, prefix))
				{
					removeBitmapData(key);
				}
			}

			var keys = fonts.keys();

			for (key in keys)
			{
				if (StringTools.startsWith(key, prefix))
				{
					removeFont(key);
				}
			}

			var keys = sounds.keys();

			for (key in keys)
			{
				if (StringTools.startsWith(key, prefix))
				{
					removeSound(key);
				}
			}
		}
    }

    private function getPath(id:String):String
    {
        return FlxModding.system.sanitize(id);   
    }

    function get_enabled():Bool
    {
        return _enabled;
    }

    function set_enabled(value:Bool):Bool
    {
        return _enabled = value;
    }
}

private class FlxLimeAssetCache extends AssetCache
{
    /**
     * Stores an asset inside the Lime asset cache.
     *
     * The asset identifier is sanitized through the modding system
     * before being forwarded to the underlying `AssetCache`.
     *
     * @param id The asset identifier.
     * @param type The type of asset being cached.
     * @param asset The asset instance to store.
     */
    override public function set(id:String, type:AssetType, asset:Dynamic):Void
    {
        super.set(getPath(id), type, asset);
    }

    /**
     * Checks whether an asset exists in the Lime cache.
     *
     * The provided asset ID is normalized before the existence
     * check occurs.
     *
     * @param id The asset identifier.
     * @param type Optional asset type filter.
     */
    override public function exists(id:String, ?type:AssetType):Bool
    {
        return super.exists(getPath(id), type);
    }

    private function getPath(id:String):String
    {
        return FlxModding.system.sanitize(id);     
    }
}