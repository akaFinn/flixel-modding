package flixel.system.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end

class FlxScriptMacro 
{
    public static macro function build():Array<Field>
    {
        var cls:ClassType = Context.getLocalClass().get();
        var fields:Array<Field> = Context.getBuildFields();

        for (meta in cls.meta.get())
        {
            switch (meta.name)
            {
                case ':buildScriptClass':
                    
                default:
                    continue;
            }
        }

        return fields;
    }
}