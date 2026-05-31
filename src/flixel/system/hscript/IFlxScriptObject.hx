package flixel.system.hscript;

interface IFlxScriptObject
{
    public function scriptSet(varName:String, varValue:Dynamic):Void;
    public function scriptGet(varName:String):Dynamic;
    public function scriptCall(funcName:String, funcArgs:Array<Dynamic>):Dynamic;
}