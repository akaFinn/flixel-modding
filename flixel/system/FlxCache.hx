package flixel.system;

import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;

enum FlxCacheType
{
	FLIXEL;
	OPENFL;
	LIME;	
}

/**
 * A custom Asset Cache system designed to replace OpenFL's/Lime's Asset Cache system.
 */
@:access(lime.utils.Assets)
@:access(openfl.utils.Assets)
@:access(lime.utils.AssetLibrary)
@:access(flixel.system.frontEnds.BitmapFrontEnd)
class FlxCache
{
	/**
	 * If this is set to false, none of the cache logic will run.
	 * It's a global toggle for whether or not anything should be cached.
	 */
	public var enabled:Bool;

	public var filter:String = "flixel";

	var bitmapData:Map<String, BitmapData>;
	var sound:Map<String, Sound>;
	var font:Map<String, Font>;

	/**
	 * Creates a new cache instance.
	 * You can optionally disable caching by passing false to the constructor.
	 */
	public function new(?enabled:Bool = true)
	{
		this.enabled = enabled;

		lime.utils.Assets.cache.enabled = false;
        openfl.utils.Assets.cache.enabled = false;

		bitmapData = new Map<String, BitmapData>();
		sound = new Map<String, Sound>();
		font = new Map<String, Font>();
	}

	/**
	 * Completely clears everything currently stored in the cache.
	 * Useful if you want to fully unload memory or reset.
	 */
	public function clear():Void
	{
		bitmapData.clear();
		sound.clear();
		font.clear();
	}

	/**
	 * Returns a list of all asset keys stored in the cache.
	 * Keys from all three asset types (bitmap, sound, font) are included.
	 */
	public function list():Array<String>
	{
		var list:Array<String> = [];
		
		for (key in bitmapData.keys())
			list.push(key);

		for (key in sound.keys())
			list.push(key);

		for (key in font.keys())
			list.push(key);

		return list;
	}

	/**
	 * Attempts to merge assets from an external cache into this cache instance.
	 * Depending on the selected type, it will try to import and clean up from:
	 * - Flixel’s internal bitmap cache
	 * - OpenFL's asset cache
	 * - Lime's asset cache
	 */
	public function merge(type:FlxCacheType):FlxCache
	{
		switch (type)
		{
			case FLIXEL:
				if (FlxModding.debug) {FlxG.log.add("Attempting to merge Flixel Cache...");}

				for (key in FlxG.bitmap._cache.keys())
				{
					setBitmapData(key, FlxG.bitmap.get(key).bitmap);
					FlxG.bitmap.removeByKey(key);
				}

				if (FlxModding.debug) {FlxG.log.add("Merged Flixel Cache!");}

			case OPENFL:
				if (FlxModding.debug) {FlxG.log.add("Attempting to merge OpenFL Cache...");}
				var cache:openfl.utils.AssetCache = Std.isOfType(openfl.utils.Assets.cache, openfl.utils.AssetCache) ? cast openfl.utils.Assets.cache : null;

				for (key in cache.bitmapData.keys())
				{
					setBitmapData(key, openfl.utils.Assets.getBitmapData(key));
					cache.removeBitmapData(key);
				}

				for (key in cache.sound.keys())
				{
					setSound(key, openfl.utils.Assets.getSound(key));
					cache.removeSound(key);
				}

				for (key in cache.font.keys())
				{
					setFont(key, openfl.utils.Assets.getFont(key));
					cache.removeFont(key);
				}

				if (FlxModding.debug) {FlxG.log.add("Merged OpenFL Cache!");}

			case LIME:
				if (FlxModding.debug) {FlxG.log.add("Attempting to merge Lime Cache...");}

				for (library in lime.utils.Assets.libraries)
				{
					for (key in library.types.keys())
					{
						var type = library.types.get(key);

						switch (type)
						{
							/*case FONT: 
								if (filter == null || StringTools.startsWith(key, filter) != false)
								{
									if (FlxModding.debug) {FlxG.log.add("Caching: " + key + ", Font");}
									setBitmapData(key, library.getFont(key));
								}*/

							case IMAGE:
								if (filter == null || StringTools.startsWith(key, filter) != false)
								{
									if (FlxModding.debug) {FlxG.log.add("Caching: " + key + ", Image");}
									setBitmapData(key, BitmapData.fromImage(library.getImage(key)));
								}

							case MUSIC, SOUND:
								if (filter == null || StringTools.startsWith(key, filter) != false)
								{
									if (FlxModding.debug) {FlxG.log.add("Caching: " + key + ", Sound");}
									setSound(key, Sound.fromAudioBuffer(library.getAudioBuffer(key)));
								}

							default:
						}

						library.types.remove(key);
					}
				}

				if (FlxModding.debug) {FlxG.log.add("Merged Lime Cache!");}
		}

		return this;
	}

	// Access Asset Values

	public function getAsset(id:String, type:FlxAssetType):Null<Any>
	{
		/*@:privateAccess
        for (key in FlxG.bitmap._cache.keys()) {trace(key);}*/
		trace(FlxG.bitmap.get(id));

		return switch (type)
		{
			case IMAGE: getBitmapData(id);
			case SOUND: getSound(id);
			case FONT: getFont(id);

			default: null;
		}
	}

	public function getBitmapData(key:String):BitmapData
	{
		//trace(key, hasBitmapData(key));
		return bitmapData.get(key);
	}

	public function getSound(key:String):Sound
	{
		return sound.get(key);
	}

	public function getFont(key:String):Font
	{
		return font.get(key);
	}

	// Store or Replace Asset Values

	public function setAsset(id:String, value:Dynamic, type:FlxAssetType):Void
	{
		switch (type)
		{
			case IMAGE: setBitmapData(id, value);
			case SOUND: setSound(id, value);
			case FONT: setFont(id, value);

			default:
		}
	}

	public function setBitmapData(key:String, value:BitmapData):Void
	{
		bitmapData.set(key, value);
	}

	public function setSound(key:String, value:Sound):Void
	{
		sound.set(key, value);
	}

	public function setFont(key:String, value:Font):Void
	{
		font.set(key, value);
	}

	// Check If Asset Exists

	public function hasAsset(key:String, type:FlxAssetType):Bool
	{
		return switch (type)
		{
			case IMAGE: hasBitmapData(key);
			case SOUND: hasSound(key);
			case FONT: hasFont(key);

			default: false;
		}
	}

	public function hasBitmapData(key:String):Bool
	{
		return bitmapData.exists(key);    
	}

	public function hasSound(key:String):Bool
	{
		return sound.exists(key);    
	}

	public function hasFont(key:String):Bool
	{
		return font.exists(key);    
	}
}
