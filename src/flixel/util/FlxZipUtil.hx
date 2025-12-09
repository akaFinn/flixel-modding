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
    /**
	 * File extensions for Zip files
	 */	
	public static var ZIP_FILE_EXTS:Array<String> = ["zip", "7z", "rar"];

    public static var cachedZipFiles:Map<String, FlxZipEntry> = new Map<String, FlxZipEntry>();

    public static function unzipFromBytes(bytes:Bytes):FlxZipEntry
    {
        var input = new BytesInput(bytes);
        var reader = new Reader(input);

        var entries = reader.read();

        return FlxZipUtil.unzipFromEntries(entries);
    }

    public static function unzipFromEntries(entries:List<Entry>):FlxZipEntry
    {
        return new FlxZipEntry(entries);
    }

    #if sys
    public static function unzipFromPath(path:String):FlxZipEntry
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

class FlxZipEntry
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
}