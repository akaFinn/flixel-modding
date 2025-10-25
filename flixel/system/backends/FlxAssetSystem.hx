package flixel.system.backends;

import flixel.util.FlxScriptUtil;
import flixel.util.helpers.FlxStringHelper;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.media.AudioBuffer;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets;
import openfl.utils.ByteArray;
import openfl.utils.Future;

#if (flixel >= "5.9.0")
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
#else
import flixel.system.backends.IAssetSystem.FlxAssetType;
#end

class FlxAssetSystem implements IAssetSystem
{
    public function new()
    {
        clear();
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