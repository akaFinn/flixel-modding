package flixel.system.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end

class FlxScriptMacro
{
    public static macro function getAllClasses():ExprOf<Array<Class<Dynamic>>>
    {
        var currentPos:Position = Context.currentPos();
        var moduleTypes:Array<ModuleType> = Context.getAllModuleTypes();
        var classExprs:Array<Expr> = [];

        for (moduleType in moduleTypes)
        {
            switch (moduleType)
            {
                case TClassDecl(classTypeRef):
                    var classType:ClassType = classTypeRef.get();

                    if (!classType.isInterface && !classType.isAbstract)
                    {
                        var fullPath = classType.module + "." + classType.name;
                        var path = fullPath.split(".");
                        classExprs.push(macro $p{path});
                    }
                
                default:
            }
        }

        return macro $v{classExprs};
    }
}