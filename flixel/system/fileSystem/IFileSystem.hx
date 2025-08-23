package flixel.system.fileSystem;

import haxe.io.Bytes;

interface IFileSystem
{
    public function createFile(path:String, name:String, data:Dynamic):Void;
    public function renameFile(path:String, name:String):Void;
    public function deleteFile(path:String):Void;
    public function isFile(path:String):Bool;

    public function getFileContent(path:String):String;
    public function getFileBytes(path:String):Bytes;

    public function setFileContent(path:String, content:String):Void;
    public function setFileBytes(path:String, bytes:Bytes):Void;

    public function readFolder(path:String):Array<String>;
    public function createFolder(path:String, name:String):Void;
    public function renameFolder(path:String, name:String):Void;
    public function deleteFolder(path:String):Void;
    public function isFolder(path:String):Bool;

    public function exists(path:String):Bool;
}