package flixel.system;

import haxe.io.Bytes;

#if sys
import sys.FileSystem;
import sys.io.File;
#else
import lime.utils.Assets;
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
     * The cached files
     */
    var files:Map<String, FlxFileEntry>;

    /**
     * The cached folders
     */
    var folders:Array<String>;
    #end

    /**
     * Creates a new FlxFileSystem instance.
     * On sys targets this wraps the real OS filesystem.
     * On non-sys targets this initializes an in-memory virtual FS.
     */
    public function new()
    {
        #if !sys
        clear();
        reload();
        #end
    }

    /**
     * Creates a file at the given path using either string data
     * or raw byte data.  
     * 
     * - On sys: Writes to actual disk using File.saveContent/saveBytes  
     * - On non-sys: Stores file data inside an in-memory Map
     *
     * @param path  The full path of the file to create
     * @param data  String or Bytes content to write
     */
    public function createFile(path:String, data:Dynamic):Void
    {
        #if sys
        if (data is String)
        {
            File.saveContent(path, data);
        }
        else if (data is Bytes)
        {
            File.saveBytes(path, data);
        }
        #else
        var parts:Array<String> = path.split("/");
        var folderPath:String = "";

        for (i in 0...parts.length - 1) 
        {
            if (folderPath != "") folderPath += "/";
            folderPath += parts[i];

            if (!folders.contains(folderPath)) createFolder(folderPath);
            if (!folders.contains(folderPath + "/")) createFolder(folderPath + "/");
        }

        files.set(path, {name: parts.pop(), data: data});
        #end
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
    public function renameFile(path:String, newPath:String):Void
    {
        #if sys
        FileSystem.rename(path, newPath);
        #else
        files[path].name = newPath.split("/").pop();
        files.set(newPath, files[path]);
        files.remove(path);
        #end
    }

    /**
     * Deletes a file at the given path.
     *
     * - On sys: Deletes the real file  
     * - On non-sys: Removes the entry from the in-memory store
     *
     * @param path The file path to delete
     */
    public function deleteFile(path:String):Void
    {
        #if sys
        FileSystem.deleteFile(path);
        #else
        files.remove(path);
        #end
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
    public function isFile(path:String):Bool
    {
        #if sys
        return !FileSystem.isDirectory(path);
        #else
        return files.exists(path);
        #end
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
    public function getFileContent(path:String):String
    {
        #if sys
        return File.getContent(path);
        #else
        return Std.string(files.get(path).data);
        #end
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
    public function getFileBytes(path:String):Bytes
    {
        #if sys
        return File.getBytes(path);
        #else
        return cast files.get(path).data;
        #end
    }

    #if !sys
    /**
     * Retrieves a file entry from the internal file map.
     *
     * - Performs a direct lookup using the given path  
     * - Does not touch the actual filesystem
     *
     * @param path The file path key used to identify the entry
     * @return The associated FlxFileEntry, or null if not found
     */
    public function getFileEntry(path:String):FlxFileEntry
    {
        return files.get(path);
    }
    #end

    /**
     * Overwrites a file with new string content.  
     * Wrapper for createFile().
     *
     * @param path     Path of the file
     * @param content  String content to write
     */
    public function setFileContent(path:String, content:String):Void
    {
        createFile(path, content);
    }

    /**
     * Overwrites a file with new byte content.  
     * Wrapper for createFile().
     *
     * @param path  Path of the file
     * @param bytes Bytes to write
     */
    public function setFileBytes(path:String, bytes:Bytes):Void
    {
        createFile(path, bytes);
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
    public function readFolder(path:String):Array<String>
    {
        #if sys
        return FileSystem.readDirectory(path);
        #else
        var result:Array<String> = [];

        for (folder in folders)
        {
            if (StringTools.startsWith(folder, path) && !result.contains(folder))
            {
                result.push(folder);
            }
        }

        for (file in files.keys())
        {
            if (StringTools.startsWith(file, path) && !result.contains(file))
            {
                result.push(file);
            }
        }

        return result;
        #end
    }

    /**
     * Creates a new folder.
     *
     * - On sys: Uses FileSystem.createDirectory  
     * - On non-sys: Adds the folder path to the virtual store
     *
     * @param path Folder to create
     */
    public function createFolder(path:String):Void
    {
        #if sys
        FileSystem.createDirectory(path);
        #else
        if (this.exists(path))
            folders.remove(path);

        folders.push(path);
        #end
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
    public function renameFolder(path:String, newPath:String):Void
    {
        #if sys
        FileSystem.rename(path, newPath);
        #else
        folders.remove(path);
        folders.push(newPath);
        #end
    }

    /**
     * Deletes a folder.
     *
     * - On sys: Removes actual directory  
     * - On non-sys: Removes stored folder entry
     *
     * @param path Folder to delete
     */
    public function deleteFolder(path:String):Void
    {
        #if sys
        FileSystem.deleteDirectory(path);
        #else
        folders.remove(path);
        #end
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
    public function isFolder(path:String):Bool
    {
        #if sys
        return FileSystem.isDirectory(path);
        #else
        return folders.contains(path);
        #end
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
    public function exists(path:String):Bool
    {
        #if sys
        return FileSystem.exists(path);
        #else
        return files.exists(path) || folders.contains(path);
        #end
    }

    #if !sys
    /**
     * Clears the memory usage for the file system
     */
    public function clear():Void
    {
        files = new Map<String, FlxFileEntry>();
        folders = [];
    }

    /**
     * Caches all assets found in lime's asset librarys
     */
    private function reload():Void
    {
        @:privateAccess
        {
            for (library in Assets.libraries)
            {
                for (key in library.cachedText.keys())
                {
                    createFile(key, library.cachedText[key]);
                }

                for (key in library.cachedBytes.keys())
                {
                    createFile(key, library.cachedBytes[key]);
                }

                for (key in library.cachedImages.keys())
                {
                    createFile(key, library.cachedImages[key]);
                }

                for (key in library.cachedAudioBuffers.keys())
                {
                    createFile(key, library.cachedAudioBuffers[key]);
                }

                for (key in library.cachedFonts.keys())
                {
                    // createFile(key, library.cachedFonts[key]);
                    trace(Type.getClassName(Type.getClass(library.cachedFonts[key])));
                }
            }

            for (file in files.keys())
            {
                trace('Cached file: $file');
            }

            for (folder in folders)
            {
                trace('Cached folder: $folder');
            }
        }
    }
    #end
}

#if !sys
/**
 * Represents a single file entry in the internal file map.
 *
 * - `name`: The filename or key associated with this entry
 * - `data`: The content of the file, format depends on context (Bytes, String, etc.)
 */
typedef FlxFileEntry =
{
    var name:String;
    var data:Dynamic;
}
#end
