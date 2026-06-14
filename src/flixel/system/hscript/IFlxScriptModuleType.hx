package flixel.system.hscript;

@:autoBuild(flixel.system.macros.FlxScriptMacro.build())
interface IFlxScriptModuleType
{
    public var name(get, never):String;
    public var pkg(get, never):Array<String>;

    private function toString():String;
}