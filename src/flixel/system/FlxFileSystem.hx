package flixel.system;

import haxe.io.Path;
import haxe.io.Bytes;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import flixel.util.FlxZipUtil;

#if sys
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
#else
import js.Browser;
import lime.utils.Assets;
#end

#if html5
import lime.graphics.Image;
import lime.app.Future;
#end

/**
 * Centralized filesystem hub that exposes *all* supported backends
 * (e.g. SysFileSystem for real disk IO and RamFileSystem for fully
 * in-memory virtual files). 
 * 
 * This class exists so modders and engine code can interact with a
 * single, unified API without caring where the data is actually stored.
 * Think of it as the master switchboard for every file operation the
 * engine supports.
 * 
 * @since 1.6.0
 */
class FlxFileSystem
{
    #if !sys
    /**
     * The cached files.
     */
    static var files:Map<String, Dynamic>;

    /**
     * The cached folders.
     */
    static var folders:Array<String>;
    #end

    /**
     * Overwrites a file with new string content.  
     *
     * @param path     Path of the file
     * @param content  String content to write
     */
    public static function setFileContent(path:String, content:String):Void
    {
        try
        {
            #if sys
            File.saveContent(path, content);
            #else
            createVirtualFileSystem();
            files.set(path, content);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Set File Content]: $e';
        }
    }

    /**
     * Overwrites a file with new byte content.  
     *
     * @param path  Path of the file
     * @param bytes Bytes to write
     */
    public static function setFileBytes(path:String, bytes:Bytes):Void
    {
        try
        {
            #if sys 
            File.saveBytes(path, bytes);
            #else
            createVirtualFileSystem();
            files.set(path, bytes);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Set File Bytes]: $e';
        }
    }

    /**
     * Reads the content of a file as a string.
     *
     * - On sys: Uses File.getContent  
     * - On non-sys: Returns Std.string() of stored data
     *
     * @param path The file path
     * @return The file content as a String
     */
    public static function getFileContent(path:String):String
    {
        try
        {
            #if sys
            return File.getContent(path);
            #else
            createVirtualFileSystem();
            return Std.string(files.get(path));
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Get File Content]: $e';
        }
    }

    /**
     * Reads the content of a file as raw bytes.
     *
     * - On sys: Uses File.getBytes  
     * - On non-sys: Returns the stored Bytes casted back
     *
     * @param path The file path
     * @return The file content as Bytes
     */
    public static function getFileBytes(path:String):Bytes
    {
        try
        {
            #if sys
            return File.getBytes(path);
            #else
            createVirtualFileSystem();

            if (files.get(path) is Bytes)
                return cast(files.get(path), Bytes);

            if (files.get(path) is String)
                return Bytes.ofString(Std.string(files.get(path)));

            return null;
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Get File Bytes]: $e';
        }
    }

    /**
     * Renames a file from one path to another.
     *
     * - On sys: Uses FileSystem.rename  
     * - On non-sys: Moves the entry inside the files map
     *
     * @param path     Original file path
     * @param newPath  New file path
     */
    public static function renameFile(path:String, newPath:String):Void
    {
        try
        {
            #if sys
            FileSystem.rename(path, newPath);
            #else
            createVirtualFileSystem();
            files.set(newPath, files[path]);
            files.remove(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Rename File]: $e';
        }
    }

    /**
     * Deletes a file at the given path.
     *
     * - On sys: Deletes the real file  
     * - On non-sys: Removes the entry from the in-memory store
     *
     * @param path The file path to delete
     */
    public static function deleteFile(path:String):Void
    {
        try
        {
            #if sys
            FileSystem.deleteFile(path);
            #else
            createVirtualFileSystem();
            files.remove(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Delete File]: $e';
        }
    }

    /**
     * Checks whether the given path refers to a file.
     *
     * - On sys: Returns true if the path exists and is *not* a directory  
     * - On non-sys: Returns true if the file exists in the map
     *
     * @param path Path to test
     * @return Whether the path represents a file
     */
    public static function isFile(path:String):Bool
    {
        try 
        {
            #if sys
            return !FileSystem.isDirectory(path);
            #else
            createVirtualFileSystem();
            return files.exists(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Detect File]: $e';
        }
    }

    /**
     * Creates a new folder.
     *
     * - On sys: Uses FileSystem.createDirectory  
     * - On non-sys: Adds the folder path to the virtual store
     *
     * @param path Folder to create
     */
    public static function createFolder(path:String):Void
    {
        try 
        {
            #if sys
            FileSystem.createDirectory(path);
            #else
            createVirtualFileSystem();
            path = Path.removeTrailingSlashes(path);

            if (!folders.contains(path))
                folders.push(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Create Folder]: $e';
        }
    }

    /**
     * Reads the contents of a folder and returns a list of its
     * direct children (files and/or folders).
     *
     * - On sys: Uses FileSystem.readDirectory  
     * - On non-sys: Returns any virtual entries starting with the path
     *
     * @param path Folder path to read
     * @return Array of entries inside the folder
     */
    public static function readFolder(path:String):Array<String>
    {
        try
        {
            #if sys
            return FileSystem.readDirectory(path);
            #else
            createVirtualFileSystem();

            var result:Array<String> = [];
            var seen:Map<String, Bool> = new Map<String, Bool>();

            path = Path.removeTrailingSlashes(path);
            var prefix:String = path == "" ? "" : path + "/";

            for (file in files.keys())
            {
                if (!StringTools.startsWith(file, prefix))
                    continue;

                var rest:String = file.substr(prefix.length);
                if (rest.indexOf("/") != -1)
                    continue;

                if (!seen.exists(rest))
                {
                    seen.set(rest, true);
                    result.push(rest);
                }
            }

            for (folder in folders)
            {
                if (!StringTools.startsWith(folder, prefix))
                    continue;

                var rest:String = folder.substr(prefix.length);
                if (rest.indexOf("/") != -1 || rest == "")
                    continue;

                if (!seen.exists(rest))
                {
                    seen.set(rest, true);
                    result.push(rest);
                }
            }

            return result;
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Read Folder]: $e';
        }
    }

    /**
     * Renames a folder.
     *
     * - On sys: Uses FileSystem.rename  
     * - On non-sys: Updates the stored folder path
     *
     * @param path    Original path
     * @param newPath New path name
     */
    public static function renameFolder(path:String, newPath:String):Void
    {
        try 
        {
            #if sys
            FileSystem.rename(path, newPath);
            #else
            createVirtualFileSystem();
            folders.remove(Path.removeTrailingSlashes(path));
            folders.push(Path.removeTrailingSlashes(newPath));
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Rename Folder]: $e';
        }
    }

    /**
     * Deletes a folder.
     *
     * - On sys: Removes actual directory  
     * - On non-sys: Removes stored folder entry
     *
     * @param path Folder to delete
     */
    public static function deleteFolder(path:String):Void
    {
        try 
        {
            #if sys
            FileSystem.deleteDirectory(path);
            #else
            createVirtualFileSystem();
            path = Path.removeTrailingSlashes(path);
            folders.remove(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Delete Folder]: $e';
        }
    }

    /**
     * Checks whether the given path represents a folder.
     *
     * - On sys: Uses FileSystem.isDirectory  
     * - On non-sys: Checks if the folder exists in the array
     *
     * @param path Path to test
     * @return Whether the path represents a folder
     */
    public static function isFolder(path:String):Bool
    {
        try 
        {
            #if sys
            return FileSystem.isDirectory(path);
            #else
            createVirtualFileSystem();
            path = Path.removeTrailingSlashes(path);
            return folders.contains(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Detect Folder]: $e';
        }
    }

    /**
     * Checks whether *any* resource exists at the given path
     * (file or folder).
     *
     * - On sys: Uses FileSystem.exists  
     * - On non-sys: Tests both virtual file and folder stores
     *
     * @param path Path to check
     * @return True if file or folder exists
     */
    public static function exists(path:String):Bool
    {
        try 
        {
            #if sys
            return FileSystem.exists(path);
            #else
            createVirtualFileSystem();
            path = Path.removeTrailingSlashes(path);
            return files.exists(path) || folders.contains(path);
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to see if File/Folder Exists]: $e';
        }
    }

    /**
     * Retrieves filesystem metadata for a file or folder.
     *
     * - On sys: Wraps `sys.FileSystem.stat` and returns the native
     *   `FileStat` data along with the entry name.
     * - On non-sys: Returns a placeholder `FlxFileStat` with default
     *   values, since real filesystem metadata is unavailable.
     *
     * This provides a unified way to query basic file information
     * without callers needing to care about platform limitations.
     *
     * @param path Path to the file or folder
     * @return A `FlxFileStat` describing the entry
     */
    public static function stat(path:String):FlxFileStat
    {
        try
        {
            #if sys
            var sysStat:FileStat = FileSystem.stat(path);

            return {
                gid: sysStat.gid,
                uid: sysStat.uid,

                atime: sysStat.atime,
                mtime: sysStat.mtime,
                ctime: sysStat.ctime,

                size: sysStat.size,

                dev: sysStat.dev,
                ino: sysStat.ino,
                nlink: sysStat.nlink,
                rdev: sysStat.rdev,
                mode: sysStat.mode,
            };
            #else
            createVirtualFileSystem();

            return {
                gid: 0,
                uid: 0,

                atime: Date.now(),
                mtime: Date.now(),
                ctime: Date.now(),

                size: 0,

                dev: 0,
                ino: 0,
                nlink: 0,
                rdev: 0,
                mode: 0,
            };
            #end
        }
        catch (e:Dynamic)
        {
            throw '[Failed to get Stats for File/Folder]: $e';
        }
    }

    /**
     * Returns the absolute, fully-resolved path of a file or folder.
     *
     * - On sys targets: Wraps `sys.FileSystem.absolutePath`, returning
     *   the platform-native absolute path.
     * - On non-sys targets: Constructs a path relative to the current
     *   browser location (HTML5) or virtual filesystem base, since real
     *   absolute paths are unavailable.
     *
     * This is useful when you need a consistent path string to reference
     * a file independent of the current working directory or relative paths.
     *
     * @param path The file or folder path to resolve
     * @return The resolved absolute path as a String
     */
    public static function absolutePath(path:String):String
    {
        #if sys
        return FileSystem.absolutePath(path);
        #else
        createVirtualFileSystem();
        return Browser.window.location.href + path;
        #end
    }

    /**
     * Returns the full canonical path of a file or folder.
     *
     * - On sys targets: Wraps `sys.FileSystem.fullPath`, resolving all
     *   symbolic links, relative segments (`.` / `..`), and normalizing
     *   the path to its canonical form.
     * - On non-sys targets: Returns a path relative to the current browser
     *   location (HTML5) and replaces forward slashes with backslashes
     *   to simulate a "full path" style.
     *
     * This function is particularly useful for comparisons between paths
     * or when the engine requires a fully-resolved, normalized path.
     *
     * @param path The file or folder path to resolve
     * @return The canonical full path as a String
     */
    public static function fullPath(path:String):String
    {
        #if sys
        return FileSystem.fullPath(path);
        #else
        createVirtualFileSystem();
        return Browser.window.location.href + StringTools.replace(path, "/", "\\");
        #end
    }

    /**
     * Extracts a ZIP archive from raw byte data into the filesystem.
     *
     * This function takes a byte array representing a ZIP file, unpacks
     * all of its entries, and recreates the folder structure at the
     * target path (minus the file extension).
     *
     * - Each entry in the archive is written using `setFileBytes`
     * - Nested directories are created automatically as needed
     * - On HTML5 targets, supported image formats are asynchronously
     *   decoded and cached into `lime.utils.Assets` for immediate use
     *
     * This provides a unified way to import compressed content into the
     * engine regardless of whether the data originated from disk,
     * network, or an in-memory source.
     *
     * @param path  Destination path used as the root folder (extension is stripped)
     * @param bytes Raw ZIP file data to extract
     */
    public static function unzipBytes(path:String, bytes:Bytes):Void
    {
        try 
        {
            var zipEntry:FlxZipEntry = FlxZipUtil.unzipFromBytes(bytes);
            var zipContents:Map<String, Bytes> = zipEntry.contents;

            FlxFileSystem.createFolder(Path.withoutExtension(path));
                
            for (zipContentPath in zipContents.keys())
            {
                var zipBytes:Bytes = zipContents.get(zipContentPath);
                var parts:Array<String> = zipContentPath.split("/");
                var folderPath:String = "";

                for (i in 0...parts.length - 1) 
                {
                    if (folderPath != "") 
                        folderPath += "/";

                    folderPath += parts[i];

                    if (!FlxFileSystem.exists(Path.withoutExtension(path) + "/" + folderPath))
                    {
                        FlxFileSystem.createFolder(Path.withoutExtension(path) + "/" + folderPath);
                    }
                }

                FlxFileSystem.setFileBytes(Path.withoutExtension(path) + "/" + zipContentPath, zipBytes);

                #if html5
                @:privateAccess
                if (Image.__isPNG(zipBytes) || Image.__isJPG(zipBytes) || Image.__isGIF(zipBytes) || Image.__isWebP(zipBytes))
                {
                    var futureImage:Future<Image> = Image.loadFromBytes(zipBytes);
                    futureImage.onComplete((image:Image) -> {Assets.cache.image.set(Path.withoutExtension(path) + "/" + zipContentPath, image);});
                    futureImage.onError((d:Dynamic) -> {throw d;});
                }
                #end
            }
        }
        catch (e:Dynamic)
        {
            throw '[Failed to Unzip Bytes]: $e';
        }
    }

    /**
     * Opens the platform-native file browser dialog.
     *
     * This is a thin wrapper around `openfl.net.FileReference.browse`
     * that wires up optional lifecycle callbacks for selection,
     * completion, and cancellation events.
     *
     * Note that this does **not** read or import the file automatically;
     * it only exposes the user-selected `FileReference` so callers can
     * decide how and when to process the file data.
     *
     * @param filters     Array of `FileFilter` objects used to limit selectable files
     * @param onSelect    (Optional) Called when a file is selected by the user
     * @param onComplete  (Optional) Called after the file operation completes successfully
     * @param onCancel    (Optional) Called if the user closes the dialog without selecting a file
     */
    public static function browseFiles(filters:Array<FileFilter>, ?onSelect:FileReference -> Void, ?onComplete:FileReference -> Void, ?onCancel:FileReference -> Void):Void
    {
        var fileRef:FileReference = new FileReference();

        if (onSelect != null) fileRef.addEventListener(Event.SELECT, (e) -> {onSelect(fileRef);});
        if (onComplete != null) fileRef.addEventListener(Event.COMPLETE, (e) -> {onComplete(fileRef);});
		if (onCancel != null) fileRef.addEventListener(Event.CANCEL, (e) -> {onCancel(fileRef);});

        fileRef.browse(filters);
    }

    #if !sys
    /**
     * Caches all files and folders found in lime's asset librarys
     */
    private static function createVirtualFileSystem():Void
    {
        if (files == null || folders == null)
        {
            files = new Map<String, Dynamic>();
            folders = [];

            @:privateAccess
            {
                for (library in Assets.libraries)
                {
                    for (key in library.cachedText.keys()) createVirtualFile(key, library.cachedText[key]);
                    for (key in library.cachedBytes.keys()) createVirtualFile(key, library.cachedBytes[key]);
                    for (key in library.cachedImages.keys()) createVirtualFile(key, library.cachedImages[key]);
                    for (key in library.cachedAudioBuffers.keys()) createVirtualFile(key, library.cachedAudioBuffers[key]);
                    for (key in library.cachedFonts.keys()) createVirtualFile(key, library.cachedFonts[key]);
                }
            }
        }
    }

    /**
     * Creates a virtual file along with its needed folders for the file system
     */
    private static function createVirtualFile(path:String, data:Dynamic):Void
    {
        var parts:Array<String> = path.split("/");
        var folderPath:String = "";

        for (i in 0...parts.length - 1) 
        {
            if (folderPath != "") folderPath += "/";
            folderPath += parts[i];

            if (!folders.contains(folderPath))
                folders.push(folderPath);
        }

        files.set(path, data);
    }
    #end
}

/**
 * Represents a platform-agnostic file stat structure.
 *
 * This typedef mirrors common file system stat information across
 * native targets, providing metadata about a file such as ownership,
 * timestamps, size, and device information.
 *
 * It is intended to be used as a lightweight data container returned
 * from file system queries rather than a mutable object.
 */
typedef FlxFileStat =
{
    var gid:Int;
    var uid:Int;

    var atime:Date;
    var mtime:Date;
    var ctime:Date;

    var size:Int;

    var dev:Int;
    var ino:Int;

    var nlink:Int;
    var rdev:Int;
    var mode:Int;
}