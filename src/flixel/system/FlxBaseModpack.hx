package flixel.system;

import flixel.system.macros.FlxModMacro;
import flixel.util.helpers.FlxStringHelper;
import flixel.util.FlxStringUtil;
import openfl.utils.Assets;

/**
 * Base representation of a modpack in the FlxModding system.
 * 
 * Provides the core structure and runtime behavior shared by all modpack types,
 * including metadata handling, directory resolution, and activation state.
 * 
 * Specialized modpack implementations (modern, Polymod, legacy) extend this
 * class to implement format-specific parsing and serialization.
 * 
 * The `@:autoBuild` macro links compile-time metadata and icon references,
 * enabling automatic setup of modpack resources.
 */
@:access(flixel.system.FlxModding)
@:autoBuild(flixel.system.macros.FlxModMacro.buildModpack())
class FlxBaseModpack extends FlxBasic
{
	/**
	 * Default active state for newly created modpacks.
	 * 
	 * Subclasses and factory methods use this value when initializing modpacks
	 * without explicitly setting the active state.
	 */
	public static var defaultActive:Bool = true;

	/**
	 * The order index of this modpack.
	 */
	public var order:Int;

	/**
	 * The folder name of this modpack.
	 * 
	 * Not a full path; resolved against the global mods directory.
	 */
	var fileName:String;

	/**
	 * Creates a new modpack instance.
	 * 
	 * @param   fileName   Folder name of the modpack (not a full path)
	 * Initializes the internal order and sets up default runtime properties.
	 */
	public function new(fileName:String)
	{
		super();

		this.fileName = fileName;
		this.order = 0;
	}

	/**
	 * Returns the full directory path of this modpack.
	 * 
	 * Combines the global mods directory with this modpack’s folder name.
	 */
	public function getDirectory():String
	{
		return FlxModding.MODS_DIRECTORY + "/" + fileName;
	}

	/**
	 * Returns the resolved path to this modpack’s metadata directory or file.
	 * 
	 * Resolution order:
	 * - Macro-defined metadata prefix (compile-time)
	 * - Default `FlxModpack.metaPrefix` fallback
	 */
	public function getMetaDirectory():String
	{
		if (FlxFileSystem.exists(getDirectory() + "/" + Reflect.field(Type.getClass(this), FlxModMacro.DEFAULT_META_MACRO_PREFIX)))
			return getDirectory() + "/" + Reflect.field(Type.getClass(this), FlxModMacro.DEFAULT_META_MACRO_PREFIX);

		return null;
	}

	/**
	 * Returns the resolved path to this modpack’s icon directory or file.
	 * 
	 * Resolution order:
	 * - Macro-defined icon prefix (compile-time)
	 * - Default `FlxModpack.iconPrefix` fallback
	 */
	public function getIconDirectory():String
	{
		if (FlxFileSystem.exists(getDirectory() + "/" + Reflect.field(Type.getClass(this), FlxModMacro.DEFAULT_ICON_MACRO_PREFIX)))
			return getDirectory() + "/" + Reflect.field(Type.getClass(this), FlxModMacro.DEFAULT_ICON_MACRO_PREFIX);

		return null;
	}

	/**
	 * Saves the current runtime metadata back to the modpack’s metadata file.
	 * 
	 * Delegates serialization to `toJsonString()` and writes to the resolved
	 * metadata directory if it exists.
	 */
	public function saveMetadataFile():Void
	{
		if (FlxFileSystem.exists(this.getMetaDirectory()))
			FlxFileSystem.setFileContent(this.getMetaDirectory(), this.toJsonString());
	}

	/**
	 * Populates this modpack from a raw dynamic metadata object.
	 * 
	 * This base implementation performs no mapping and is intended to be
	 * overridden by subclasses that define format-specific metadata.
	 * 
	 * @param   data   Dynamic object representing parsed metadata
	 * @return  This modpack instance (for chaining or compatibility)
	 */
	public function fromDynamic(data:Dynamic):FlxBaseModpack
	{
		return this;
	}

	/**
	 * Populates this modpack from a JSON string.
	 * 
	 * Parses the JSON into a dynamic object and delegates to `fromDynamic()`.
	 * If parsing fails, logs a warning and uses a null fallback.
	 * 
	 * @param   text   JSON string representing mod metadata
	 * @return  This modpack instance
	 */
	public function fromJsonString(text:String):FlxBaseModpack
	{
		try 
		{
			return this.fromDynamic(FlxStringHelper.parseJsonString(text));
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn("Failed to make Modpack '" + fileName + "' from Json, string is invalid.");
			return this.fromDynamic(null);
		}
	}

	/**
	 * Serializes this modpack into a JSON string.
	 * 
	 * This base implementation returns an empty string and is expected
	 * to be overridden by subclasses with format-specific serialization.
	 */
	public function toJsonString():String
	{
		return "";
	}

	/**
	 * Calculates the total size of this modpack in bytes.
	 * 
	 * Recursively sums the sizes of all files and subdirectories
	 * contained within the modpack folder.
	 * 
	 * @return  Total size of the modpack in bytes
	 */
	public function getModpackSize():Int
	{
		function getFolderSize(path:String):Int
		{
			var total:Int = 0;

			for (entry in FlxFileSystem.readFolder(path))
        	{
				var fullPath = FlxFileSystem.fullPath(path + "/" + entry);

				if (FlxFileSystem.isFolder(fullPath))
            	{
					total += getFolderSize(fullPath);
				}
            	else
            	{
					total += FlxFileSystem.stat(fullPath).size;
				}
			}

			return total;
		}

		return getFolderSize(getDirectory());
	}

	/**
	 * Cleans up this modpack instance.
	 * 
	 * Clears internal references before delegating to `super.destroy()`.
	 */
	override public function destroy():Void
    {
		fileName = null;
        super.destroy();   
    }

    /**
	 * Returns a formatted debug string for this modpack.
	 * 
	 * Includes class type, directory path, active state, and total size.
	 * Useful for logging or console inspection.
	 * 
	 * @return  Human-readable debug string
	 */
    override public function toString():String
    {
        return FlxStringUtil.getDebugString([
			LabelValuePair.weak("class", Type.getClassName(Type.getClass(this))),
			LabelValuePair.weak("path", getDirectory()),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("size", FlxStringUtil.formatBytes(getModpackSize()))
		]);
    }

	/**
	 * Updates the active state of this modpack.
	 * 
	 * Dispatches activation or deactivation signals when the state changes,
	 * allowing the system to react accordingly.
	 * 
	 * @param   Value   The new active state
	 * @return  The assigned value
	 */
	override function set_active(Value:Bool):Bool
	{
		active = Value;

		if (Value != false)
			FlxModding.signals.onModActived.dispatch(this);
		else
			FlxModding.signals.onModDeactived.dispatch(this);

		return Value;
	}

	/**
	 * Factory method to create and initialize a modpack instance.
	 * 
	 * If a specific subclass is provided, an instance is created and
	 * populated from its metadata. Otherwise, a base modpack is returned
	 * with default active state.
	 * 
	 * @param   fileName   The modpack folder name
	 * @param   cls        Optional modpack class to instantiate
	 * @return  Fully initialized modpack instance
	 */
	public static function fromModpackClass(fileName:String, ?cls:Class<FlxBaseModpack>):FlxBaseModpack
	{
		if (cls != null)
		{
			var modpack:FlxBaseModpack = Type.createInstance(cls, [fileName]);
			modpack.fromJsonString(FlxFileSystem.getFileContent(modpack.getMetaDirectory()));
			return modpack;
		}

		var modpack:FlxBaseModpack = new FlxBaseModpack(fileName);
		modpack.active = FlxBaseModpack.defaultActive;
		return modpack;
	}
}