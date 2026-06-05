package flixel.system.hscript;

interface IFlxScriptObject
{
    public function s_set(varName:String, varValue:Dynamic):Void;
    public function s_get(varName:String):Dynamic;
    public function s_call(funcName:String, funcArgs:Array<Dynamic>):Dynamic;
}