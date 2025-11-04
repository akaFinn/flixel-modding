package lime.utils;

import flixel.FlxG;
import haxe.io.Path;
import flixel.util.FlxScriptUtil;
import flixel.util.helpers.FlxStringHelper;
import lime.text.Font;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import flixel.system.FlxModding;
import lime.app.Future;

/**
 * TODO: Add comments to EVERYTHINGG!!!!
 * 
 * @author akaFinn
 * 
 * @since 1.6.0
 */
@:access(flixel.system.FlxModding)
class ModdedAssetLibrary extends AssetLibrary
{
    public var defaultLibrary:AssetLibrary;

    public function new(?defaultLibrary:AssetLibrary)
    {
        super();

        if (defaultLibrary != null) 
        {
            this.defaultLibrary = defaultLibrary;

            for (key in defaultLibrary.classTypes.keys())
			{
				this.classTypes.set(key, defaultLibrary.classTypes.get(key));
			}

            for (key in defaultLibrary.types.keys())
			{
				this.types.set(key, defaultLibrary.types.get(key));
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

			case TEMPLATE: throw "Not sure how to get template: " + id;
			default: throw "Unknown asset type: " + type;
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

			case TEMPLATE: throw "Not sure how to load template: " + id;
			default: throw "Unknown asset type: " + type;
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
        return FlxModding.system.fileSystem.exists(FlxModding.system.sanitize(id));
    }

    override public function list(type:String):Array<String>
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

        addFiles(FlxModding.ASSETS_DIRECTORY);

		return list;
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
		trace("Checking if id is local as default: " + id);
        return super.isLocal(id, type);
    }

    public function isLocalModded(id:String, type:String):Bool
    {
		return true;
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
        var santizedPathway:String = getPathModded(id);
        var moddedTextContent:String = FlxModding.system.fileSystem.getFileContent(santizedPathway);
        var defaultTextContent:String = FlxModding.system.fileSystem.getFileContent(id);

        var hasMergePathway:Bool = StringTools.contains(santizedPathway, "/" + FlxStringHelper.DEFAULT_MERGE_PREFIX + "/");
        var hasAppendPathway:Bool = StringTools.contains(santizedPathway, "/" + FlxStringHelper.DEFAULT_APPEND_PREFIX + "/");
        var hasSourcePathway:Bool = StringTools.contains(santizedPathway, "/" + FlxScriptUtil.DEFAULT_SOURCE_PREFIX + "/");

        if (hasMergePathway || hasAppendPathway || hasSourcePathway)
        {
            if (hasMergePathway)
            {
                if (FlxStringHelper.XML_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.mergeXmlText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.JSON_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.mergeJsonText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.SRT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.mergeSrtText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.TEXT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.mergePlainText(defaultTextContent, moddedTextContent);
                }
                else
                {
                    FlxG.log.warn("File extension not recognized, merging assets as plain text");
                    return FlxStringHelper.mergePlainText(defaultTextContent, moddedTextContent);
                }
            }

            if (hasAppendPathway)
            {
                if (FlxStringHelper.XML_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.appendXmlText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.JSON_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.appendJsonText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.SRT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.appendSrtText(defaultTextContent, moddedTextContent);
                }
                else if (FlxStringHelper.TEXT_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    return FlxStringHelper.appendPlainText(defaultTextContent, moddedTextContent);
                }
                else
                {
                    FlxG.log.warn("File extension not recognized, appending assets as plain text");
                    return FlxStringHelper.appendPlainText(defaultTextContent, moddedTextContent);
                }
            }

            /*if (hasSourcePathway)
            {
                if (FlxScriptUtil.HAXE_FILE_EXTS.contains(Path.extension(santizedPathway)))
                {
                    // TODO: Finish this
                    // Not done LOLOLOLOL
                    return null;
                }
            }*/
        }

        return moddedTextContent;
    }

    override public function getBytes(id:String):Bytes
    {
        if (isDefaultAsset(id))
            return getBytesDefault(id);
        else
            return getBytesModded(id);
    }

    public function getBytesDefault(id:String):Bytes
    {
        return super.getBytes(id);
    }

    public function getBytesModded(id:String):Bytes
    {
        return Bytes.fromBytes(FlxModding.system.fileSystem.getFileBytes(getPathModded(id)));
    }

    override public function getImage(id:String):Image
    {
        if (isDefaultAsset(id))
            return getImageDefault(id);
        else
            return getImageModded(id);
    }

    public function getImageDefault(id:String):Image
    {
        return super.getImage(id);    
    }

    public function getImageModded(id:String):Image
    {
        if (Assets.cache.image.exists(getPathModded(id)))
            return Assets.cache.image.get(getPathModded(id));

        var image:Image = Image.fromFile(getPathModded(id));
        Assets.cache.image.set(getPathModded(id), image);
        return image;
    }

    override public function getAudioBuffer(id:String):AudioBuffer
    {
        if (isDefaultAsset(id))
            return getAudioBufferDefault(id);
        else
            return getAudioBufferModded(id);
    }

    public function getAudioBufferDefault(id:String):AudioBuffer
    {
        return super.getAudioBuffer(id);
    }

    public function getAudioBufferModded(id:String):AudioBuffer
    {
        if (Assets.cache.audio.exists(getPathModded(id)))
            return Assets.cache.audio.get(getPathModded(id));

        var audio:AudioBuffer = AudioBuffer.fromFile(getPathModded(id));
        Assets.cache.audio.set(getPathModded(id), audio);
        return audio;
    }

    override public function getFont(id:String):Font
    {
        if (isDefaultAsset(id))
            return getFontDefault(id);
        else
            return getFontModded(id);
    }

    public function getFontDefault(id:String):Font
    {
        return super.getFont(id);
    }

    public function getFontModded(id:String):Font
    {
        if (Assets.cache.font.exists(getPathModded(id)))
            return Assets.cache.font.get(getPathModded(id));

        var font:Font = Font.fromFile(getPathModded(id));
        Assets.cache.font.set(getPathModded(id), font);
        return font;
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

    override public function loadBytes(id:String):Future<Bytes>
    {
        if (isDefaultAsset(id))
            return loadBytesDefault(id);
        else
            return loadBytesModded(id);
    }

    public function loadBytesDefault(id:String):Future<Bytes>
    {
        return super.loadBytes(id);    
    }

    public function loadBytesModded(id:String):Future<Bytes>
    {
        return Future.withValue(getBytesModded(id));
    }

    override public function loadImage(id:String):Future<Image>
    {
        if (isDefaultAsset(id))
            return loadImageDefault(id);
        else
            return loadImageModded(id);
    }

    public function loadImageDefault(id:String):Future<Image>
    {
        return super.loadImage(id);
    }

    public function loadImageModded(id:String):Future<Image>
    {
        return Future.withValue(getImageModded(id));
    }

    override public function loadAudioBuffer(id:String):Future<AudioBuffer>
    {
        if (isDefaultAsset(id))
            return loadAudioBufferDefault(id);
        else
            return loadAudioBufferModded(id);
    }

    public function loadAudioBufferDefault(id:String):Future<AudioBuffer>
    {
        return super.loadAudioBuffer(id);    
    }

    public function loadAudioBufferModded(id:String):Future<AudioBuffer>
    {
        return Future.withValue(getAudioBufferModded(id));
    }

    override public function loadFont(id:String):Future<Font>
    {
        if (isDefaultAsset(id))
            return loadFontDefault(id);
        else
            return loadFontModded(id);
    }

    public function loadFontDefault(id:String):Future<Font>
    {
        return super.loadFont(id);
    }

    public function loadFontModded(id:String):Future<Font>
    {
        return Future.withValue(getFontModded(id));    
    }

    function isDefaultAsset(id:String):Bool
    {
        return FlxModding.system.hasBlacklistedDirectory(id);
    }
}