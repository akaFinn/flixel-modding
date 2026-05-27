package flixel.util;

import haxe.ds.List;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.Entry;
import haxe.zip.Reader;
import openfl.utils.Assets;

#if (!cpp && !hl && !neko)
import haxe.zip.InflateImpl;
import haxe.io.BytesBuffer;
#end

/**
 * A static utility class for working with Zip archives.
 * 
 * Provides functions to extract files from bytes or directly
 * from Haxe Zip entries, returning a convenient map of
 * filenames to their decompressed content.
 * 
 * @since 1.6.0
 */
class FlxZipUtil
{
    /**
     * Takes a `Bytes` object representing a Zip archive
     * and decompresses all entries inside it.
     * 
     * This method automatically handles both compressed
     * and uncompressed entries, returning their contents
     * as a `Map` where the key is the file name and the value
     * is the file data in bytes.
     * 
     * @param   bytes   The raw bytes of the Zip archive
     * @return  A map of file names to decompressed bytes
     */
    public static function unzipFromBytes(bytes:Bytes):FlxZipEntry
    {
        var input:BytesInput = new BytesInput(bytes);
        var reader:Reader = new Reader(input);

        var entries:List<Entry> = reader.read();

        if (FlxZipUtil.getZipFormat(bytes) != UNKNOWN)
            return FlxZipUtil.unzipFromEntries(entries);

        FlxG.log.warn("Failed to unzip bytes, unknown zip format.");
        return null;
    }

    /**
     * Takes a `List<Entry>` representing the contents of a Zip archive
     * and decompresses each entry as necessary.
     * 
     * This function will decompress entries marked as compressed
     * and leave uncompressed entries intact. All data is returned
     * as a `Map` keyed by filename.
     * 
     * @param   entries   The Zip entries to process
     * @return  A map of file names to decompressed bytes
     */
    public static function unzipFromEntries(entries:List<Entry>):FlxZipEntry
    {
        var zipEntry:FlxZipEntry = {size: 0, contents: new Map<String, Bytes>()};

        for (entry in entries)
        {
            var entryData:Bytes = entry.data;
            var entryName:String = entry.fileName;

            if (!StringTools.endsWith(entryName, "/"))
            {
                if (entry.compressed != false)
                {
                    #if (cpp || hl || neko)
                    entryData = Reader.unzip(entry);
                    #else
                    var returnBuf:BytesBuffer = new BytesBuffer();

                    var bytesInput:BytesInput = new BytesInput(entryData);
                    var inflater:InflateImpl = new InflateImpl(bytesInput, false, false);

                    var unzipBuf:Bytes = Bytes.alloc(65535);
                    var bytesRead:Int = inflater.readBytes(unzipBuf, 0, unzipBuf.length);

                    while (bytesRead == unzipBuf.length)
                    {
                        returnBuf.addBytes(unzipBuf, 0, bytesRead);
                        bytesRead = inflater.readBytes(unzipBuf, 0, unzipBuf.length);
                    }

                    returnBuf.addBytes(unzipBuf, 0, bytesRead);
                    entryData = returnBuf.getBytes();
                    #end
                }

                zipEntry.size += entryData.length;
                zipEntry.contents.set(entryName, entryData);
            }
        }

        return zipEntry;
    }

    /**
     * Loads a Zip archive from a file system path and extracts all entries.
     *
     * Verifies that the path exists, reads the file as raw bytes, and then
     * delegates decompression to `unzipFromBytes`.
     *
     * @param   path   The file system path to the Zip archive
     * @return         A map of entry paths to their decompressed bytes
     */
    public static function unzipFromPath(path:String):FlxZipEntry
    {
        if (!Assets.exists(path))
        {
            FlxG.log.warn('Cannot unzip from path: "$path", as the path does not exist.');
        }

        return FlxZipUtil.unzipFromBytes(Assets.getBytes(path));
    }

    /**
     * Attempts to determine the archive format based on magic header bytes.
     *
     * This performs a very lightweight signature check using the first
     * few bytes of the file, rather than relying on file extensions.
     *
     * - `"PK"` -> ZIP
     * - `"7z"` -> 7-Zip
     * - `"Rar!"` -> WinRAR
     *
     * @param   bytes   Raw bytes of the archive
     * @return          The detected Zip format, or `UNKNOWN` if unsupported
     */
    public static function getZipFormat(bytes:Bytes):FlxZipFormat
    {
        if (bytes.length != 0)
        {
            if (bytes.getString(0, 2) == "PK")
                return ZIP;

            if (bytes.getString(0, 2) == "7z")
                return SEVEN_ZIP;

            if (bytes.getString(0, 4) == "Rar!")
                return WINRAR;
        }
        
        return UNKNOWN;
    }
}

/**
 * Represents the fully extracted contents of a Zip archive.
 *
 * Stores high-level metadata about the archive along with
 * a map of file paths to their decompressed byte data.
 */
typedef FlxZipEntry = 
{
    /**
     * The total combined size (in bytes) of all extracted entries.
     */
    var size:Int;

    /**
     * A map of entry paths to their decompressed contents.
     *
     * The key is the full internal Zip path, and the value
     * is the raw byte data of that entry.
     */
    var contents:Map<String, Bytes>;
}

/**
 * Supported archive formats detectable by `FlxZipUtil`.
 *
 * Used primarily for quick identification via magic bytes,
 * not for full validation or extraction guarantees.
 */
enum FlxZipFormat
{
    /** Standard ZIP archive format */
    ZIP;

    /** 7-Zip archive format */
    SEVEN_ZIP;

    /** WinRAR archive format */
    WINRAR;

    /** Unknown or unsupported archive format */
    UNKNOWN;   
}