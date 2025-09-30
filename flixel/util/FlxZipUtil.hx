package flixel.util;

import flixel.FlxG;
import haxe.ds.List;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.Entry;
import haxe.zip.Reader;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FlxZipUtil
{
    public static inline var ZIP_PREFIX:String = ".zip";

    public static inline var SEVENZIP_PREFIX:String = ".7z";
    
    public static inline var WINRAR_PREFIX:String = ".rar";

    public static var cachedZipFiles:Map<String, FlxZipFile> = new Map<String, FlxZipFile>();

    public static function unzipFromBytes(bytes:Bytes):FlxZipFile
    {
        var input = new BytesInput(bytes);
        var reader = new Reader(input);

        var entries = reader.read();

        return FlxZipUtil.unzipFromEntries(entries);
    }

    public static function unzipFromEntries(entries:List<Entry>):FlxZipFile
    {
        return new FlxZipFile(entries);
    }

    #if sys
    public static function unzipFromPath(path:String):FlxZipFile
    {
        if (FileSystem.exists(path))
        {
            var bytes:Bytes = File.getBytes(path);
            return FlxZipUtil.unzipFromBytes(bytes);
        }
        else
        {
            FlxG.log.error('Failed to locate Zip from path: $path');
            return null;
        }
    }
    #end
}

class FlxZipFile
{
    public var contents:Map<String, Bytes>;
    
    public function new(entries:List<Entry>)
    {
        contents = new Map<String, Bytes>();

        for (entry in entries)
        {
            var data = Reader.unzip(entry);
            contents.set(entry.fileName, data);
        }
    }

    public static function filterContentKeys(keys:Iterator<String>):Array<String>
    {
        var result:Array<String> = [];

	    var dirs:Array<String> = [];
	    var files:Array<String> = [];

	    for (key in keys)
	    {
		    if (StringTools.endsWith(key, "/"))
		    {
			    dirs.push(key);
		    }
		    else
		    {
			    files.push(key);
		    }
	    }

	    result = dirs.concat(files);

        return result;
    }
}