package flixel.system.fileSystems;

import flixel.util.FlxZipUtil.FlxZipFile;
import flixel.util.FlxZipUtil;
import haxe.io.Bytes;

#if sys
class SysZipFileSystem extends SysFileSystem
{
    public static var instance:SysZipFileSystem;

    public function new()
    {
        super();
        SysZipFileSystem.instance = this;
    }

    override public function createFile(path:String, name:String, data:Dynamic):Void
    {
        if (isZipFile(path))
        {
            var zipFile:FlxZipFile = getZipFile(path);
            var zipPath:String = getZipAssetPath(path + (StringTools.endsWith(path, "/") ? "" : "/") + name);

            zipFile.contents.set(path + (StringTools.endsWith(path, "/") ? "" : "/") + name, data);
        }

        super.createFile(path, name, data);
    }

    override public function renameFile(path:String, name:String):Void
    {
        super.renameFile(path, name);
    }

    override public function deleteFile(path:String):Void
    {
        super.deleteFile(path);
    }

    override public function isFile(path:String):Bool
    {
        if (isZipFile(path))
        {
            return !isFolder(path);
        }

        return super.isFile(path);
    }

    override public function getFileContent(path:String):String
    {
        if (isZipFile(path))
        {
            var zipFile:FlxZipFile = getZipFile(path);
            var zipPath:String = getZipAssetPath(path);

            return zipFile.contents.get(zipPath).toString();
        }

        return super.getFileContent(path);
    }

    override public function getFileBytes(path:String):Bytes
    {
        if (isZipFile(path))
        {
            var zipFile:FlxZipFile = getZipFile(path);
            var zipPath:String = getZipAssetPath(path);

            return zipFile.contents.get(zipPath);
        }

        return super.getFileBytes(path);
    }

    override public function setFileContent(path:String, content:String):Void
    {
        super.setFileContent(path, content);
    }

    override public function setFileBytes(path:String, bytes:Bytes):Void
    {
        super.setFileBytes(path, bytes);
    }

    override public function readFolder(path:String):Array<String>
    {
        return super.readFolder(path);
    }

    override public function createFolder(path:String, name:String):Void
    {
        super.createFolder(path, name);
    }

    override public function renameFolder(path:String, name:String):Void
    {
        super.renameFolder(path, name);
    }

    override public function deleteFolder(path:String):Void
    {
        super.deleteFolder(path);
    }

    override public function isFolder(path:String):Bool
    {
        if (isZipFile(path))
        {
            var zipFile:FlxZipFile = getZipFile(path);
            var zipPath:String = getZipAssetPath(path);

            return StringTools.endsWith(zipPath, "/");
        }

        return super.isFolder(path);
    }

    override public function exists(path:String):Bool
    {
        if (isZipFile(path))
        {
            var zipFile:FlxZipFile = getZipFile(path);
            var zipPath:String = getZipAssetPath(path);

            return zipFile.contents.exists(zipPath);
        }

        return super.exists(path);
    }

    private function isZipFile(id:String):Bool
    {
        return StringTools.contains(id, FlxZipUtil.ZIP_PREFIX) && !StringTools.endsWith(id, FlxZipUtil.ZIP_PREFIX);
    }

    private function getZipFile(id:String):FlxZipFile
    {
        var index:Int = id.indexOf(FlxZipUtil.ZIP_PREFIX);
        var result:String = (index != -1) ? id.substr(0, index + 4) : id;

        return FlxZipUtil.cachedZipFiles.get(result);
    }

    private function getZipAssetPath(id:String):String
    {
        var index:Int = id.indexOf(FlxZipUtil.ZIP_PREFIX + "/");
        if (index == -1) return "";

        return id.substr(index + 5);
    }
}
#end