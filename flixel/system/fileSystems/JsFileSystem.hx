package flixel.system.fileSystems;

#if (js && html5)
import js.Browser;

class JsFileSystem extends RamFileSystem
{
    public static var instance:JsFileSystem;

    public function new()
    {
        super();
		JsFileSystem.instance = this;
    }
}
#end
