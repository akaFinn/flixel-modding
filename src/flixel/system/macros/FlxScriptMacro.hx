package flixel.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
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
                    var getStaticField:Field = {
                        name: 'getStatic',
                        access: [APublic],
                        kind: FieldType.FFun({
                            args: [],
                            ret: macro:Dynamic
                        }),
                        pos: Context.currentPos()
                    };

                    fields.push(getStaticField);
                default:
                    continue;
            }
        }

        return fields;
    }
}