package flixel.system.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end

class FlxScriptMacro
{
    public static function createScriptClassObject(superClass:Class<Dynamic>, args:Array<Dynamic>):Dynamic
    {
        #if macro
        var localClass:ClassType = Context.getLocalClass().get();
        var fields:Array<ClassField> = localClass.fields.get();

        for (field in fields)
        {
            trace('${field.name}: ${field.expr()}');
        }

        return macro $v{'Hi'}
        #else
        return null;
        #end
    }
}