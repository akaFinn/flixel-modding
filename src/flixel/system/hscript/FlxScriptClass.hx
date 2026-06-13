package flixel.system.hscript;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

import haxe.Constraints.Function;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptClass implements IFlxScriptModuleType
{
    public var pkg(get, never):Array<String>;

    function get_pkg():Array<String>
    {
        if (module.pkg[module.pkg.length - 1] == this.name)
        {
            return module.pkg;
        }

        var pkgClone:Array<String> = module.pkg.copy();
        pkgClone.push(this.name);
        return pkgClone;
    }

    public var name(get, never):String;

    function get_name():String
    {
        return this.decl.name;
    }

    public var isPrivate(get, never):Bool;

    function get_isPrivate():Bool
    {
        return this.decl.isPrivate;
    }

    public var isAbstract(get, never):Bool;

    function get_isAbstract():Bool
    {
        return this.decl.isAbstract;
    }

    public var isExtern(get, never):Bool;
    
    function get_isExtern():Bool
    {
        return this.decl.isExtern;
    }

    public var isFinal(get, never):Bool;
    
    function get_isFinal():Bool
    {
        return this.decl.isFinal;
    }

    public var superClass:Class<Dynamic>;

    var constructor:FlxScriptClassField;

    var classFields:Map<String, FlxScriptClassField> = [];

    var staticFields:Map<String, FlxScriptClassField> = [];

    var staticInterp:Interp;

    var module:FlxScriptModule;

    var decl:ClassDecl;

    public function new(module:FlxScriptModule, decl:ClassDecl)
    {
        this.module = module;
        this.decl = decl;

        staticInterp = module.interp.copy();
        
        if (decl.extend != null)
        {
            switch (decl.extend)
            {
                case CTPath(path, params):
                    var fullPath:String = path.join(".");

                    if (staticInterp.hasVar(fullPath))
                        superClass = staticInterp.resolve(fullPath);
                    else 
                        superClass = Type.resolveClass(fullPath);

                default:
            }
        }

        if (decl.implement != null && decl.implement.length != 0)
        {
            for (implement in decl.implement)
            {
                trace(new Printer().typeToString(implement));
            }
        }

        if (decl.constructor != null)
            constructor = new FlxScriptClassField(this, decl.constructor);

        for (fieldDecl in decl.staticFields.concat(decl.fields))
        {
            var scriptField:FlxScriptClassField = new FlxScriptClassField(this, fieldDecl);
            classFields.set(fieldDecl.name, scriptField);

            if (fieldDecl.access.contains(AStatic))
                staticFields.set(fieldDecl.name, scriptField);
        }

        /*var scriptClassObj:Class<Dynamic> = getScriptObj();
        staticInterp.setVar(name, scriptClassObj);
        module.interp.setVar(name, scriptClassObj);*/
    }

    public function s_new(?args:Array<Dynamic>):Dynamic
    {
        // Come back to this later. - akaFinn
        return null;
    }

    public function s_staticSet(varName:String, varValue:Dynamic):Dynamic
    {
        if (staticFields.exists(varName))
        {
            var staticField:FlxScriptClassField = staticFields.get(varName);

            if (!staticField.isFunction)
            {
                return staticField.value = varValue;
            }
            
            FlxG.log.warn('Failed to Set Variable for ScriptClass, "${varName}" exists but it is not a variable.');
            return null;
        }

        FlxG.log.warn('Failed to Set Variable for ScriptClass, "${this.name}" does not have the Variable "${varName}"');
        return null;
    }

    public function s_staticGet(varName:String):Dynamic
    {
        if (staticFields.exists(varName))
            return staticFields.get(varName);

        FlxG.log.warn('Failed to Get Variable for ScriptClass, "${this.name}" does not have the Variable "${varName}"');
        return null;
    }

    public function s_staticCall(funcName:String, funcArgs:Array<Dynamic>):Dynamic
    {
        if (staticFields.exists(funcName))
            return Reflect.callMethod(null, staticFields.get(funcName).value, funcArgs);
        
        FlxG.log.warn('Failed to Call Function for ScriptClass, "${this.name}" does not have the Function "${funcName}"');
        return null;
    }

    public /*macro*/ function getScriptObj():Class<Dynamic>
    {
        var scriptClassObj:Class<Dynamic> = null;
        return scriptClassObj;
    }

    private function toString():String
    {
        if (staticFields.exists('toString'))
            return staticFields.get('toString').value();

        return 'FlxScriptClass<${name}>';
    }
}

private typedef FlxScriptClassFieldParams = 
{
    var script:FlxScriptClass;
    var decl:FieldDecl;
}

@:callable private abstract FlxScriptClassField(FlxScriptClassFieldParams) from Dynamic to Dynamic
{
    public var name(get, never):String;

    function get_name():String
    {
        return this.decl.name;
    }

    public var access(get, never):Array<FieldAccess>;

    function get_access():Array<FieldAccess>
    {
        return this.decl.access;
    }

    public var metadata(get, never):Metadata;

    function get_metadata():Metadata
    {
        return this.decl.meta;
    }

    public var isFinal(get, never):Bool;

    function get_isFinal():Bool
    {
        return this.decl.access.contains(AFinal);
    }

    public var isStatic(get, never):Bool;

    function get_isStatic():Bool
    {
        return this.decl.access.contains(AStatic);
    }

    public var isFunction(get, never):Bool;

    function get_isFunction():Bool
    {
        switch (this.decl.kind) 
        {
            case KVar(varDecl): return false;
            case KFunction(functionDecl): return true;
        }
    }

    public var getAccess(get, never):VarProperty;

    function get_getAccess():VarProperty
    {
        switch (this.decl.kind) 
        {
            case KVar(varDecl): return varDecl.get;
            case KFunction(functionDecl): return null;
        }
    }

    public var setAccess(get, never):VarProperty;

    function get_setAccess():VarProperty
    {
        switch (this.decl.kind) 
        {
            case KVar(varDecl): return varDecl.set;
            case KFunction(functionDecl): return null;
        }
    }

    var interp(get, never):Interp;

    function get_interp():Interp
    {
        @:privateAccess return this.script.staticInterp;
    }

    public var value(get, set):Dynamic;

    function get_value():Dynamic
    {
        return interp.resolve(name);
    }

    function set_value(v:Dynamic):Dynamic
    {
        return interp.setVar(name, v);
    }

    public function new(script:FlxScriptClass, decl:FieldDecl)
    {
        this = {script: script, decl: decl};
        
        switch (decl.kind) 
        {
            case KVar(varDecl):
                var value:Dynamic = null;

                if (varDecl.expr != null)
                    value = interp.expr(varDecl.expr);

                interp.setVar(name, value, decl);

            case KFunction(functionDecl):
                var minArgLength:Int = 0;
                var argNames:Array<String> = [];
                var copy:Interp = interp;

                for (arg in functionDecl.args) 
                {
                    argNames.push(arg.name);

                    if (!arg.opt && arg.value == null)
                        minArgLength++;
                }

                var func:Array<Dynamic>->Dynamic = function(args:Array<Dynamic>) 
                {
                    if (args.length < minArgLength)
                    {
                        FlxG.log.warn('Invalid number of parameters. Got ${args.length}, required ${minArgLength} for function "${decl.name}"');
                        return null;
                    }

                    var funcReturn:Dynamic = null;
                    var argIndex:Int = 0;

                    for (arg in functionDecl.args)
                    {
                        var argName:String = arg.name;
                        var argValue:Dynamic = null;

                        if (args != null && argIndex < args.length)
                            argValue = args[argIndex];
                        else if (arg.value != null)
                            argValue = copy.expr(arg.value);

                        if (argValue != null || arg.opt)
                        {
                            @:privateAccess copy.locals.set(argName, {r: argValue, isfinal: false});
                        }
                        argIndex++;
                    }

                    @:privateAccess
                    funcReturn = copy.exprReturn(functionDecl.expr);
                    return funcReturn;
                };

                var value:Function = Reflect.makeVarArgs(func);
                interp.setVar(name, value, decl);
        }
    }

    private function toString():String
    {
        return Std.string(get_value());
    }

    @:to private function toDynamic():Dynamic
    {
        return get_value();
    }
}