package flixel.system.hscript;

interface IFlxScriptModuleType
{
    public var name(get, never):String;
    public var pkg(get, never):Array<String>;

    private function toString():String;

    public function getScriptObj():IFlxScriptModuleObj;
}

interface IFlxScriptModuleObj 
{
    var script:IFlxScriptModuleType;
}