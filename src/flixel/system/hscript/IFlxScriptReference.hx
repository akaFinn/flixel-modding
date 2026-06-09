package flixel.system.hscript;

interface IFlxScriptReference
{
    public var name(get, never):String;
    public var pkg(get, never):Array<String>;

    private function toString():String;
}