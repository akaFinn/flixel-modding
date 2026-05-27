package flixel.system;

import flixel.FlxG;
import flixel.system.FlxModding;
import flixel.util.helpers.FlxStringHelper;
import openfl.text.Font as OpenFlFont;
import lime.text.Font;
import lime.utils.Bytes;
import lime.utils.Assets;
import lime.utils.AssetBundle;
import lime.utils.AssetManifest;
import lime.utils.AssetLibrary;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.app.Future;
import haxe.io.Path;

// TODO: Add comments to functions without any.

/**
 * Custom AssetLibrary implementation with Flixel modding support.
 *
 * This library transparently overrides Lime's asset loading pipeline
 * to allow modded assets to replace or extend default game assets.
 *
 * - Default assets are resolved through Lime's AssetLibrary
 * - Modded assets are resolved through FlxModding's virtual file system
 * - Supports merging and appending for text-based assets
 * 
 * @since 1.6.0
 */
class FlxAssetLibrary extends AssetLibrary
{
    /**
     * Creates a new FlxAssetLibrary instance.
     *
     * Initialization is delegated entirely to the base AssetLibrary.
     */
    public function new()
    {
        super();
    }

    /**
     * Creates an asset library from raw bytes.
     *
     * Typically used when loading embedded or packaged asset manifests.
     *
     * @param bytes    Manifest data as bytes
     * @param rootPath Optional root path override
     */
    public static function fromBytes(bytes:Bytes, rootPath:String = null):FlxAssetLibrary
	{
		return fromManifest(AssetManifest.fromBytes(bytes, rootPath));
	}

    /**
     * Creates an asset library from a manifest file on disk.
     *
     * @param path     Path to the manifest file
     * @param rootPath Optional root path override
     */
	public static function fromFile(path:String, rootPath:String = null):FlxAssetLibrary
	{
		return fromManifest(AssetManifest.fromFile(path, rootPath));
	}

    /**
     * Creates an asset library from an AssetBundle.
     *
     * @param bundle Asset bundle containing preloaded assets
     */
	public static function fromBundle(bundle:AssetBundle):FlxAssetLibrary
	{
		return fromAssetLibrary(AssetLibrary.fromBundle(bundle));
	}

    /**
     * Creates an asset library from an AssetManifest.
     *
     * @param manifest Parsed asset manifest
     */
	public static function fromManifest(manifest:AssetManifest):FlxAssetLibrary
	{
		return fromAssetLibrary(AssetLibrary.fromManifest(manifest));
	}

    /**
     * Wraps an existing Lime AssetLibrary.
     *
     * Copies all internal caches and metadata into a FlxAssetLibrary
     * to allow seamless modded asset overrides.
     *
     * @param limeLibrary Existing Lime asset library
     */
    public static function fromAssetLibrary(limeLibrary:AssetLibrary):FlxAssetLibrary
    {
        var library = new FlxAssetLibrary();
        library.__fromLibrary(limeLibrary);
        return library;
    }

    override public function exists(id:String, type:String):Bool
    {
        if (isDefaultAsset(getPath(id), type.toUpperCase()))
            return super.exists(id, type);
        else
            return FlxFileSystem.exists(getPath(id));
    }

    override public function list(type:String):Array<String>
    {
        /*var result:Array<String> = [];

		function addFiles(directory:String, prefix = "")
		{
			for (path in FlxFileSystem.readFolder(directory))
			{
				if (FlxFileSystem.isFolder(directory + "/" + path))
					addFiles(directory + "/" + path, prefix + path + "/");
				else
					result.push(FlxModding.system.sanitize(prefix + path));
			}
		}

        addFiles(FlxModding.ASSETS_DIRECTORY);*/

		return super.list(type);
    }

    override public function isLocal(id:String, type:String):Bool
    {
        if (isDefaultAsset(getPath(id), type.toUpperCase()))
			return super.isLocal(id, type);
        else
            return true;
    }
    
    override public function getPath(id:String):String
    {
        return FlxModding.system.sanitize(id); 
    }

    override public function getText(id:String):String
    {
        if (isDefaultAsset(getPath(id), "TEXT"))
            return this.getTextDefault(id);
        else
            return this.getTextModded(id);
    }

    private function getTextAppended(id:String):String
    {
        var path:String = getPath(id);
        var extension:String = Path.extension(path);

        var defaultText:String = FlxFileSystem.getFileContent(id);
        var moddedText:String = FlxFileSystem.getFileContent(path);

        if (FlxStringHelper.XML_FILE_EXTS.contains(extension))
            return FlxStringHelper.appendXmlText(defaultText, moddedText);
        else if (FlxStringHelper.JSON_FILE_EXTS.contains(extension))
            return FlxStringHelper.appendJsonText(defaultText, moddedText);
        else if (FlxStringHelper.SRT_FILE_EXTS.contains(extension))
            return FlxStringHelper.appendSrtText(defaultText, moddedText);
        else if (FlxStringHelper.TEXT_FILE_EXTS.contains(extension))
            return FlxStringHelper.appendPlainText(defaultText, moddedText);
        else
        {
            FlxG.log.warn("File extension not recognized, appending assets as plain text");
            return FlxStringHelper.appendPlainText(defaultText, moddedText);
        }
    }

    private function getTextMerged(id:String):String
    {
        var path:String = getPath(id);
        var extension:String = Path.extension(path);

        var defaultText:String = FlxFileSystem.getFileContent(id);
        var moddedText:String = FlxFileSystem.getFileContent(path);

        if (FlxStringHelper.XML_FILE_EXTS.contains(extension))
            return FlxStringHelper.mergeXmlText(defaultText, moddedText);
        else if (FlxStringHelper.JSON_FILE_EXTS.contains(extension))
            return FlxStringHelper.mergeJsonText(defaultText, moddedText);
        else if (FlxStringHelper.SRT_FILE_EXTS.contains(extension))
            return FlxStringHelper.mergeSrtText(defaultText, moddedText);
        else if (FlxStringHelper.TEXT_FILE_EXTS.contains(extension))
            return FlxStringHelper.mergePlainText(defaultText, moddedText);
        else
        {
            FlxG.log.warn("File extension not recognized, merging assets as plain text");
            return FlxStringHelper.mergePlainText(defaultText, moddedText);
        }
    }

    private function getTextDefault(id:String):String
    {
        return super.getText(id);
    }

    private function getTextModded(id:String):String
    {
        var path:String = getPath(id);

        if (StringTools.contains(path, "/" + FlxStringHelper.DEFAULT_MERGE_PREFIX + "/")) 
            return this.getTextMerged(id);

        if (StringTools.contains(path, "/" + FlxStringHelper.DEFAULT_APPEND_PREFIX + "/")) 
            return this.getTextAppended(id);

        return FlxFileSystem.getFileContent(path);
    }

    override public function getBytes(id:String):Bytes
    {
        if (isDefaultAsset(getPath(id), "BYTES"))
            return this.getBytesDefault(id);
        else
            return this.getBytesModded(id);
    }

    private function getBytesDefault(id:String):Bytes
    {
        return super.getBytes(id);
    }

    private function getBytesModded(id:String):Bytes
    {
        return Bytes.fromBytes(FlxFileSystem.getFileBytes(getPath(id)));
    }

    override public function getImage(id:String):Image
    {
        if (isDefaultAsset(getPath(id), "IMAGE"))
            return this.getImageDefault(id);
        else
            return this.getImageModded(id);
    }

    private function getImageDefault(id:String):Image
    {
        return super.getImage(id);    
    }

    private function getImageModded(id:String):Image
    {
        var path:String = getPath(id);
        var image:Image = null;

        if (Assets.cache.image.exists(path) && Assets.cache.enabled)
            return Assets.cache.image.get(path);

        image = Image.fromBytes(FlxFileSystem.getFileBytes(path));

        if (Assets.cache.enabled)
            Assets.cache.image.set(path, image);

        return image;
    }

    override public function getAudioBuffer(id:String):AudioBuffer
    {
        if (isDefaultAsset(getPath(id), "SOUND"))
            return this.getAudioBufferDefault(id);
        else
            return this.getAudioBufferModded(id);
    }

    private function getAudioBufferDefault(id:String):AudioBuffer
    {
        return super.getAudioBuffer(id);
    }

    private function getAudioBufferModded(id:String):AudioBuffer
    {
        var path:String = getPath(id);
        var audio:AudioBuffer = null;

        if (Assets.cache.audio.exists(path) && Assets.cache.enabled)
            return Assets.cache.audio.get(path);

        audio = AudioBuffer.fromBytes(FlxFileSystem.getFileBytes(path));

        if (Assets.cache.enabled)
            Assets.cache.audio.set(path, audio);
        
        return audio;
    }

    override public function getFont(id:String):Font
    {
        if (isDefaultAsset(getPath(id), "FONT"))
            return this.getFontDefault(id);
        else
            return this.getFontModded(id);
    }

    private function getFontDefault(id:String):Font
    {
        return super.getFont(id);
    }

    private function getFontModded(id:String):Font
    {
        var path:String = getPath(id);
        var font:OpenFlFont = null;

        if (Assets.cache.font.exists(path) && Assets.cache.enabled)
            return Assets.cache.font.get(path);

        font = OpenFlFont.fromBytes(FlxFileSystem.getFileBytes(path));
        
        @:privateAccess
        if (!OpenFlFont.__fontByName.exists(font.fontName))
            OpenFlFont.registerFont(font);

        if (Assets.cache.enabled)
            Assets.cache.font.set(path, font);
        
        return font;
    }

    override public function loadText(id:String):Future<String>
    {
        if (isDefaultAsset(getPath(id), "TEXT"))
            return this.loadTextDefault(id);
        else
            return this.loadTextModded(id);
    }

    private function loadTextDefault(id:String):Future<String>
    {
        return super.loadText(id);    
    }

    private function loadTextModded(id:String):Future<String>
    {
        return Future.withValue(getTextModded(id));
    }

    override public function loadBytes(id:String):Future<Bytes>
    {
        if (isDefaultAsset(getPath(id), "BYTES"))
            return this.loadBytesDefault(id);
        else
            return this.loadBytesModded(id);
    }

    private function loadBytesDefault(id:String):Future<Bytes>
    {
        return super.loadBytes(id);    
    }

    private function loadBytesModded(id:String):Future<Bytes>
    {
        return Future.withValue(getBytesModded(id));
    }

    override public function loadImage(id:String):Future<Image>
    {
        if (isDefaultAsset(getPath(id), "IMAGE"))
            return this.loadImageDefault(id);
        else
            return this.loadImageModded(id);
    }

    private function loadImageDefault(id:String):Future<Image>
    {
        return super.loadImage(id);
    }

    private function loadImageModded(id:String):Future<Image>
    {
        return Image.loadFromFile(getPath(id));
    }

    override public function loadAudioBuffer(id:String):Future<AudioBuffer>
    {
        if (isDefaultAsset(getPath(id), "SOUND"))
            return this.loadAudioBufferDefault(id);
        else
            return this.loadAudioBufferModded(id);
    }

    private function loadAudioBufferDefault(id:String):Future<AudioBuffer>
    {
        return super.loadAudioBuffer(id);    
    }

    private function loadAudioBufferModded(id:String):Future<AudioBuffer>
    {
        return AudioBuffer.loadFromFile(getPath(id));
    }

    override public function loadFont(id:String):Future<Font>
    {
        if (isDefaultAsset(getPath(id), "FONT"))
            return this.loadFontDefault(id);
        else
            return this.loadFontModded(id);
    }

    private function loadFontDefault(id:String):Future<Font>
    {
        return super.loadFont(id);
    }

    private function loadFontModded(id:String):Future<Font>
    {
        #if (js && html5)
        return Font.loadFromName(getPath(id));
        #else
        return Font.loadFromFile(getPath(id));
        #end
    }

    /**
     * Checks whether an asset should be resolved as a default asset.
     *
     * This includes:
     * - Blacklisted directories
     * - Embedded class-based assets
     * - Assets already cached by Lime
     *
     * @param id   Asset identifier
     * @param type Optional asset type
     */
    private function isDefaultAsset(id:String, ?type:String):Bool
    {
        //@:privateAccess trace('${id}: ${!StringTools.startsWith(id, FlxModding.MODS_DIRECTORY)}, ${FlxModding.system.hasBlacklistedDirectory(id)}, ${super.isLocal(id, type)}');
        @:privateAccess return !StringTools.startsWith(id, FlxModding.MODS_DIRECTORY) || FlxModding.system.hasBlacklistedDirectory(id) || super.isLocal(id, type);
    }

    /**
     * Copies internal state from another AssetLibrary instance.
     * @param library Source AssetLibrary
     */
    private function __fromLibrary(library:AssetLibrary):Void
    {
        this.assetsLoaded = library.assetsLoaded;
        this.assetsTotal = library.assetsTotal;

        this.bytesLoaded = library.bytesLoaded;
        this.bytesTotal = library.bytesTotal;
        this.promise = library.promise;
        this.loaded = library.loaded;

        for (key in library.cachedAudioBuffers.keys()) {this.cachedAudioBuffers.set(key, library.cachedAudioBuffers[key]);}
        for (key in library.cachedBytes.keys()) {this.cachedBytes.set(key, library.cachedBytes[key]);}
        for (key in library.cachedFonts.keys()) {this.cachedFonts.set(key, library.cachedFonts[key]);}
        for (key in library.cachedImages.keys()) {this.cachedImages.set(key, library.cachedImages[key]);}
        for (key in library.cachedText.keys()) {this.cachedText.set(key, library.cachedText[key]);}

        for (key in library.classTypes.keys()) {this.classTypes.set(key, library.classTypes[key]);}

        for (key in library.pathGroups.keys()) {this.pathGroups.set(key, library.pathGroups[key]);}
        for (key in library.paths.keys()) {this.paths.set(key, library.paths[key]);}
        for (key in library.preload.keys()) {this.preload.set(key, library.preload[key]);}

        for (key in library.sizes.keys()) {this.sizes.set(key, library.sizes[key]);}
        for (key in library.types.keys()) {this.types.set(key, library.types[key]);}

        if (library.bytesLoadedCache != null)
        {
            this.bytesLoadedCache = new Map<String, Int>();

            for (key in library.bytesLoadedCache.keys())
            {
                this.bytesLoadedCache.set(key, library.bytesLoadedCache[key]);
            }
        }  
    }
}