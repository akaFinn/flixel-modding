package flixel.system;

import flixel.util.FlxScriptUtil;
import flixel.util.helpers.FlxStringHelper;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.media.AudioBuffer;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.utils.ByteArray;
import openfl.utils.Future;

#if (flixel >= "5.9.0")
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
#else
enum abstract FlxAssetType(String)
{
	var BINARY = "binary";
	var FONT = "font";
	var IMAGE ="image";
	var SOUND = "sound";
	var TEXT = "text";
	
	public function toOpenFlType()
	{
		return switch((cast this:FlxAssetType))
		{
			case BINARY: AssetType.BINARY;
			case FONT: AssetType.FONT;
			case IMAGE: AssetType.IMAGE;
			case SOUND: AssetType.SOUND;
			case TEXT: AssetType.TEXT;
		}
	}
}
#end

class FlxAssetSystem
{
    public static var instance:FlxAssetSystem;

    public function new()
    {
        clear();
        FlxAssetSystem.instance = this;
    }

    public function getAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
    {   
        if (isOpenFLAsset(id))
        {
            return getOpenFLAsset(id, type, useCache != false);
        }
        else
        {
            var santizedPathway:String = FlxModding.system.sanitize(id);

            var textContent:String = FlxModding.system.fileSystem.getFileContent(santizedPathway);
            var binaryContent:Bytes = FlxModding.system.fileSystem.getFileBytes(santizedPathway);

            switch (type)
		    {
                case TEXT:
                    var hasMergePathway:Bool = StringTools.contains(santizedPathway, "/" + FlxStringHelper.DEFAULT_MERGE_PREFIX + "/");
                    var hasAppendPathway:Bool = StringTools.contains(santizedPathway, "/" + FlxStringHelper.DEFAULT_APPEND_PREFIX + "/");
                    var hasSourcePathway:Bool = StringTools.contains(santizedPathway, "/" + FlxScriptUtil.DEFAULT_SOURCE_PREFIX + "/");

                    if (hasMergePathway || hasAppendPathway || hasSourcePathway)
                    {
                        var defaultTextContent:String = FlxModding.system.fileSystem.getFileContent(id);

                        if (hasMergePathway)
                        {

                            if (FlxStringHelper.XML_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.mergeXmlText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.JSON_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.mergeJsonText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.SRT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.mergeSrtText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.TEXT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.mergePlainText(defaultTextContent, textContent);
                            }
                            else
                            {
                                FlxG.log.warn("File extension not recognized, merging assets as plain text");
                                return FlxStringHelper.mergePlainText(defaultTextContent, textContent);
                            }
                        }

                        if (hasAppendPathway)
                        {
                            if (FlxStringHelper.XML_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.appendXmlText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.JSON_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.appendJsonText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.SRT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.appendSrtText(defaultTextContent, textContent);
                            }
                            else if (FlxStringHelper.TEXT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                return FlxStringHelper.appendPlainText(defaultTextContent, textContent);
                            }
                            else
                            {
                                FlxG.log.warn("File extension not recognized, appending assets as plain text");
                                return FlxStringHelper.appendPlainText(defaultTextContent, textContent);
                            }
                        }

                        /*if (hasSourcePathway)
                        {
                            if (FlxScriptUtil.HAXE_FILE_EXTS.contains(Path.extension(santizedPathway)))
                            {
                                // Not done LOLOLOLOL
                                return null;
                            }
                        }*/
                    }

                    return textContent;
			    case BINARY:
				    return binaryContent;
			
			    case IMAGE if (useCache && Assets.cache.hasBitmapData(santizedPathway)):
				    return Assets.cache.getBitmapData(santizedPathway);
			    case SOUND if (useCache && Assets.cache.hasSound(santizedPathway)):
				    return Assets.cache.getSound(santizedPathway);
			    case FONT if (useCache && Assets.cache.hasFont(santizedPathway)):
				    return Assets.cache.getFont(santizedPathway);
			
			    case IMAGE:
				    var bitmap = BitmapData.fromBytes(ByteArray.fromBytes(binaryContent));
				    if (useCache != false) Assets.cache.setBitmapData(santizedPathway, bitmap);

				    return bitmap;
			    case SOUND:
				    var sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(binaryContent));
				    if (useCache != false) Assets.cache.setSound(santizedPathway, sound);

				    return sound;
			    case FONT:
				    var font = Font.fromBytes(ByteArray.fromBytes(binaryContent));
				    if (useCache != false) Assets.cache.setFont(santizedPathway, font);

				    return font;
		    }
        }
    }

    public function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>
    {
        return Future.withValue(getAsset(id, type, useCache != false));
    }

    public function exists(id:String, ?type:FlxAssetType):Bool
    {
        if (isOpenFLAsset(id))
            return Assets.exists(id, type.toOpenFlType());

        return FlxModding.system.fileSystem.exists(FlxModding.system.sanitize(id));
    }

    public function clear():Void
    {
        Assets.cache.clear();
    }

	public function list(?type:FlxAssetType):Array<String>
	{
		var list:Array<String> = [];

		function addFiles(directory:String, prefix = "")
		{
			for (path in FlxModding.system.fileSystem.readFolder(directory))
			{
				if (FlxModding.system.fileSystem.isFolder(directory + "/" + path))
					addFiles(directory + "/" + path, prefix + path + "/");
				else
					list.push(FlxModding.system.sanitize(prefix + path));
			}
		}

		@:privateAccess
        addFiles(FlxModding.assetDirectory);
		return list;
	}

    public function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool
    {
        if (isOpenFLAsset(id) && useCache != false)
			return Assets.isLocal(id, type.toOpenFlType());

        return true;
    }

    public function getText(id:String, useCache:Bool = true):String
    {
        return getAsset(id, TEXT, useCache != false);
    }

    public function getBytes(id:String, useCache:Bool = true):Bytes
    {
        return getAsset(id, BINARY, useCache != false);
    }

    public function getBitmapData(id:String, useCache:Bool = true):BitmapData
    {
        return getAsset(id, IMAGE, useCache != false);
    }

    public function getSound(id:String, useCache:Bool = true):Sound
    {
        return getAsset(id, SOUND, useCache != false);
    }

    public function getFont(id:String, useCache:Bool = true):Font
    {
        return getAsset(id, FONT, useCache != false);
    }

    function isOpenFLAsset(id:String):Bool
    {
        @:privateAccess
        return StringTools.startsWith(id, FlxModding.flixelDirectory) || StringTools.contains(id, ":");
    }

    function getOpenFLAsset(id:String, type:FlxAssetType, useCache:Bool = true):Null<Any>
	{
		return switch (type)
		{
            case TEXT: Assets.getText(id);
			case BINARY: Assets.getBytes(id);
			case IMAGE: Assets.getBitmapData(id, useCache != false);
			case SOUND: Assets.getSound(id, useCache != false);
			case FONT: Assets.getFont(id, useCache != false);
		}
	}
}

/**
 * @author akaFinn
 * @since 1.4.0
 */
@:access(lime.utils.AssetLibrary)
@:access(flixel.system.FlxModding)
class AssetModLibrary extends AssetLibrary
{
    public var defaultLibrary:lime.utils.AssetLibrary;

    public function new(?defaultLibrary:lime.utils.AssetLibrary)
    {
        super();

        if (defaultLibrary != null) 
        {
            this.defaultLibrary = defaultLibrary;

            for (key in defaultLibrary.classTypes.keys())
            {
                if (StringTools.startsWith(key, FlxModding.flixelDirectory))
                {
                    this.classTypes.set(key, defaultLibrary.classTypes.get(key));
                }
            }

            for (key in defaultLibrary.types.keys())
            {
                if (StringTools.startsWith(key, FlxModding.flixelDirectory))
                {
                    this.types.set(key, defaultLibrary.types.get(key));       
                }
            }
        }
    }

    override public function getAsset(id:String, type:String):Dynamic
    {
        if (isDefaultAsset(id))
            return getAssetDefault(id, type);
        else
            return getAssetModded(id, type);
    }

    public function getAssetDefault(id:String, type:String):Dynamic
    {
        return super.getAsset(id, type);
    }

    public function getAssetModded(id:String, type:String):Dynamic
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: getBytes(id);
            case TEXT: getText(id);
			case IMAGE: getImage(id);
            case FONT: getFont(id);
			case MUSIC, SOUND: getAudioBuffer(id);

			default: FlxG.log.error("Unknown asset type: " + type); null;
		}
    }

    override public function loadAsset(id:String, type:String):Future<Dynamic>
    {
        if (isDefaultAsset(id))
            return loadAssetDefault(id, type);
        else
            return loadAssetModded(id, type);
    }

    public function loadAssetDefault(id:String, type:String):Future<Dynamic>
    {
        return super.loadAsset(id, type);
    }

    public function loadAssetModded(id:String, type:String):Future<Dynamic>
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: loadBytes(id);
            case TEXT: loadText(id);
			case IMAGE: loadImage(id);
            case FONT: loadFont(id);
			case MUSIC, SOUND: loadAudioBuffer(id);

			default: FlxG.log.error("Unknown asset type: " + type); null;
		}
    }

    override public function exists(id:String, type:String):Bool
    {
        if (isDefaultAsset(id))
            return existsDefault(id, type);
        else
            return existsModded(id, type);
    }

    public function existsDefault(id:String, type:String):Bool
    {
        return super.exists(id, type);
    }

    public function existsModded(id:String, type:String):Bool
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: FlxModding.system.assets.exists(id, BINARY);
			case TEXT: FlxModding.system.assets.exists(id, TEXT);
			case IMAGE: FlxModding.system.assets.exists(id, IMAGE);
            case FONT: FlxModding.system.assets.exists(id, FONT);
			case MUSIC, SOUND: FlxModding.system.assets.exists(id, SOUND);

			default: FlxG.log.error("Unknown asset type: " + type); false;
		}
    }

    override public function list(type:String):Array<String>
    {
        var result:Array<String>;

        if (type != null)
        {
            result = switch (cast(type, AssetType))
		    {
			    case BINARY: FlxModding.system.assets.list(BINARY);
			    case TEXT: FlxModding.system.assets.list(TEXT);
			    case IMAGE: FlxModding.system.assets.list(IMAGE);
                case FONT: FlxModding.system.assets.list(FONT);
			    case MUSIC, SOUND: FlxModding.system.assets.list(SOUND);

			    default: FlxG.log.error("Unknown asset type: " + type); [];
		    }
        }
        else
        {
            result = FlxModding.system.assets.list();
        }

        return result;
    }

    override public function isLocal(id:String, type:String):Bool
    {
        if (isDefaultAsset(id))
            return isLocalDefault(id, type);
        else
            return isLocalModded(id, type);
    }

    public function isLocalDefault(id:String, type:String):Bool
    {
        return super.isLocal(id, type);
    }

    public function isLocalModded(id:String, type:String):Bool
    {
        return switch (cast(type, AssetType))
		{
			case BINARY: FlxModding.system.assets.isLocal(id, BINARY);
			case TEXT: FlxModding.system.assets.isLocal(id, TEXT);
			case IMAGE: FlxModding.system.assets.isLocal(id, IMAGE);
            case FONT: FlxModding.system.assets.isLocal(id, FONT);
			case MUSIC, SOUND: FlxModding.system.assets.isLocal(id, SOUND);

			default: FlxG.log.error("Unknown asset type: " + type); false;
		}
    }

    override public function getPath(id:String):String
    {
        if (isDefaultAsset(id))
            return getPathDefault(id);
        else
            return getPathModded(id);
    }

    public function getPathDefault(id:String):String
    {
        return super.getPath(id);    
    }

    public function getPathModded(id:String):String
    {
        return FlxModding.system.sanitize(id);    
    }

    override public function getText(id:String):String
    {
        if (isDefaultAsset(id))
            return getTextDefault(id);
        else
            return getTextModded(id);
    }

    public function getTextDefault(id:String):String
    {
        return super.getText(id);
    }

    public function getTextModded(id:String):String
    {
        return FlxModding.system.assets.getText(id);    
    }

    override public function getBytes(id:String):lime.utils.Bytes
    {
        if (isDefaultAsset(id))
            return getBytesDefault(id);
        else
            return getBytesModded(id);
    }

    public function getBytesDefault(id:String):lime.utils.Bytes
    {
        return super.getBytes(id);
    }

    public function getBytesModded(id:String):lime.utils.Bytes
    {
        return lime.utils.Bytes.fromBytes(FlxModding.system.assets.getBytes(id));
    }

    override public function getImage(id:String):lime.graphics.Image
    {
        if (isDefaultAsset(id))
            return getImageDefault(id);

        return lime.graphics.Image.fromBitmapData(FlxModding.system.assets.getBitmapData(id));
    }

    public function getImageDefault(id:String):lime.graphics.Image
    {
        return super.getImage(id);    
    }

    public function getImageModded(id:String):lime.graphics.Image
    {
        return lime.graphics.Image.fromBitmapData(FlxModding.system.assets.getBitmapData(id));
    }

    override public function getAudioBuffer(id:String):lime.media.AudioBuffer
    {
        if (isDefaultAsset(id))
            return getAudioBufferDefault(id);
        else
            return getAudioBufferModded(id);
    }

    public function getAudioBufferDefault(id:String):lime.media.AudioBuffer
    {
        return super.getAudioBuffer(id);
    }

    public function getAudioBufferModded(id:String):lime.media.AudioBuffer
    {
        @:privateAccess
        return FlxModding.system.assets.getSound(id).__buffer;    
    }

    override public function getFont(id:String):lime.text.Font
    {
        if (isDefaultAsset(id))
            return getFontDefault(id);
        else
            return getFontModded(id);
    }

    public function getFontDefault(id:String):lime.text.Font
    {
        return super.getFont(id);
    }

    public function getFontModded(id:String):lime.text.Font
    {
        return FlxModding.system.assets.getFont(id);
    }

    override public function getMovieClip(id:String):openfl.display.MovieClip
    {
        if (isDefaultAsset(id))
            return getMovieClipDefault(id);
        else
            return getMovieClipModded(id);
    }

    public function getMovieClipDefault(id:String):openfl.display.MovieClip
    {
        return super.getMovieClip(id);    
    }

    public function getMovieClipModded(id:String):openfl.display.MovieClip
    {
        return null; 
    }

    override public function loadText(id:String):Future<String>
    {
        if (isDefaultAsset(id))
            return loadTextDefault(id);
        else
            return loadTextModded(id);
    }

    public function loadTextDefault(id:String):Future<String>
    {
        return super.loadText(id);    
    }

    public function loadTextModded(id:String):Future<String>
    {
        return Future.withValue(getTextModded(id));
    }

    override public function loadBytes(id:String):Future<lime.utils.Bytes>
    {
        if (isDefaultAsset(id))
            return loadBytesDefault(id);
        else
            return loadBytesModded(id);
    }

    public function loadBytesDefault(id:String):Future<lime.utils.Bytes>
    {
        return super.loadBytes(id);    
    }

    public function loadBytesModded(id:String):Future<lime.utils.Bytes>
    {
        return Future.withValue(getBytesModded(id));
    }

    override public function loadImage(id:String):Future<lime.graphics.Image>
    {
        if (isDefaultAsset(id))
            return loadImageDefault(id);
        else
            return loadImageModded(id);
    }

    public function loadImageDefault(id:String):Future<lime.graphics.Image>
    {
        return super.loadImage(id);
    }

    public function loadImageModded(id:String):Future<lime.graphics.Image>
    {
        return Future.withValue(getImageModded(id));
    }

    override public function loadAudioBuffer(id:String):Future<lime.media.AudioBuffer>
    {
        if (isDefaultAsset(id))
            return loadAudioBufferDefault(id);
        else
            return loadAudioBufferModded(id);
    }

    public function loadAudioBufferDefault(id:String):Future<lime.media.AudioBuffer>
    {
        return super.loadAudioBuffer(id);    
    }

    public function loadAudioBufferModded(id:String):Future<lime.media.AudioBuffer>
    {
        return Future.withValue(getAudioBufferModded(id));
    }

    override public function loadFont(id:String):Future<lime.text.Font>
    {
        if (isDefaultAsset(id))
            return loadFontDefault(id);
        else
            return loadFontModded(id);
    }

    public function loadFontDefault(id:String):Future<lime.text.Font>
    {
        return super.loadFont(id);
    }

    public function loadFontModded(id:String):Future<lime.text.Font>
    {
        return Future.withValue(getFontModded(id));    
    }

    override public function loadMovieClip(id:String):Future<openfl.display.MovieClip>
    {
        if (isDefaultAsset(id))
            return loadMovieClipDefault(id);
        else
            return loadMovieClipModded(id);
    }

    public function loadMovieClipDefault(id:String):Future<openfl.display.MovieClip>
    {
        return super.loadMovieClip(id);
    }
    
    public function loadMovieClipModded(id:String):Future<openfl.display.MovieClip>
    {
        return Future.withValue(getMovieClipModded(id));
    }

    function isDefaultAsset(id:String):Bool
    {
        return StringTools.startsWith(id, FlxModding.flixelDirectory);
    }
}