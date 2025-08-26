package flixel.system.fileSystem;

import haxe.io.Bytes;

// This is all unused until I figure out web modding
// Sorrrrrrrrrrrrrrrrry looooool - finn
class WebFileSystem implements IFileSystem
{
    public function new() {}

    public function createFile(path:String, name:String, data:Dynamic):Void
    {
        // if (data is String)
            // File.saveContent(path + (StringTools.endsWith(path, "/") ? "" : "/") + name, data);
        // else if (data is Bytes)
            // File.saveBytes(path + (StringTools.endsWith(path, "/") ? "" : "/") + name, data);
    }

    public function renameFile(path:String, name:String):Void
    {
        //if (this.isFile(path))
            // FileSystem.rename(path, path.substr(0, path.lastIndexOf("/")) + "/" + name);
    }

    public function deleteFile(path:String):Void
    {
        // FileSystem.deleteFile(path);
    }

    public function isFile(path:String):Bool
    {
        return false;
    }

    public function getFileContent(path:String):String
    {
        return "";
    }

    public function getFileBytes(path:String):Bytes
    {
        return Bytes.ofString("");
    }

    public function setFileContent(path:String, content:String):Void
    {
        // File.saveContent(path, content);
    }

    public function setFileBytes(path:String, bytes:Bytes):Void
    {
        // File.saveBytes(path, bytes);
    }

    public function readFolder(path:String):Array<String>
    {
        return [];
    }

    public function createFolder(path:String, name:String):Void
    {
        // FileSystem.createDirectory(path + (StringTools.endsWith(path, "/") ? "" : "/") + name);
    }

    public function renameFolder(path:String, name:String):Void
    {
        // if (this.isFolder(path))
            // FileSystem.rename(path, path.substr(0, path.lastIndexOf("/")) + "/" + name);
    }

    public function deleteFolder(path:String):Void
    {
        // FileSystem.deleteDirectory(path);
    }

    public function isFolder(path:String):Bool
    {
        return false;
    }

    public function exists(path:String):Bool
    {
        return false;
    }
}