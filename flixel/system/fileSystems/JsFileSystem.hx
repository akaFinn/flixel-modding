package flixel.system.fileSystems;

import haxe.Json;
import haxe.io.Bytes;
import lime.app.Application;

#if (js && html5)
import js.Browser;

class JsFileSystem extends RamFileSystem
{
    public static var instance:JsFileSystem;

    public function new()
    {
        super();
        JsFileSystem.instance = this;

        var raw = Browser.window.localStorage.getItem(Application.current.meta["company"]);
        if (raw != null)
        {
            var data:Dynamic = Json.parse(raw);

            if (data.files != null)
            {
                for (k in Reflect.fields(data.files))
                {
                    var v:Dynamic = Reflect.field(data.files, k);
                    if (Std.isOfType(v, String))
                        files.set(k, Bytes.ofString(v));
                    else
                        files.set(k, v);
                }
            }
            
            if (data.folders != null)
            {
                for (k in Reflect.fields(data.folders))
                {
                    var v:Dynamic = Reflect.field(data.folders, k);
                    folders.set(k, v);
                }
            }
        }
    }

    inline function save():Void
    {
        var obj = {
            files: [for (k in files.keys()) k => Std.string(files.get(k))],
            folders: [for (k in folders.keys()) k => folders.get(k)]
        };

        Browser.window.localStorage.setItem(Application.current.meta["company"], Json.stringify(obj));
    }

    override public function createFile(path:String, name:String, data:Dynamic):Void
    {
        super.createFile(path, name, data);
        save();
    }

    override public function renameFile(path:String, name:String):Void
    {
        super.renameFile(path, name);
        save();
    }

    override public function deleteFile(path:String):Void
    {
        super.deleteFile(path);
        save();
    }

    override public function setFileContent(path:String, content:String):Void
    {
        super.setFileContent(path, content);
        save();
    }

    override public function setFileBytes(path:String, bytes:Bytes):Void
    {
        super.setFileBytes(path, bytes);
        save();
    }

    override public function createFolder(path:String, name:String):Void
    {
        super.createFolder(path, name);
        save();
    }

    override public function renameFolder(path:String, name:String):Void
    {
        super.renameFolder(path, name);
        save();
    }

    override public function deleteFolder(path:String):Void
    {
        super.deleteFolder(path);
        save();
    }
}
#end
