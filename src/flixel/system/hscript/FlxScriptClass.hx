package flixel.system.hscript;

import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptClass
{
    var pkg(get, never):Array<String>;

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

    var name(get, never):String;

    function get_name():String
    {
        return this.decl.name;
    }

    var isPrivate(get, never):Bool;

    function get_isPrivate():Bool
    {
        return this.decl.isPrivate;
    }

    var isAbstract(get, never):Bool;

    function get_isAbstract():Bool
    {
        return this.decl.isAbstract;
    }

    var isExtern(get, never):Bool;
    
    function get_isExtern():Bool
    {
        return this.decl.isExtern;
    }

    var isFinal(get, never):Bool;
    
    function get_isFinal():Bool
    {
        return this.decl.isFinal;
    }

    var superClass:Class<Dynamic>;

    var staticFields:Map<String, Dynamic> = [];

    var staticInterp:Interp;
    
    var fieldDecls:Map<String, FieldDecl> = [];

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
                case CTPath(path, _):
                    var fullPath:String = path.join(".");

                    if (staticInterp.hasVar(fullPath))
                        superClass = staticInterp.resolve(fullPath);
                    else 
                        superClass = Type.resolveClass(fullPath);

                default:
            }
        }

        var staticClass:Dynamic = {};

        for (fieldDecl in decl.fields)
        {
            fieldDecls.set(fieldDecl.name, fieldDecl);

            if (fieldDecl.access.contains(AStatic) && !Interp.KEYWORDS.contains(fieldDecl.name))
            {
                // trace('Adding StaticField: "${fieldDecl.name}"');

                var fieldInfo:VarInfo = staticInterp.field(fieldDecl);

                staticFields.set(fieldDecl.name, fieldInfo.v);
                staticInterp.forceVar(fieldDecl.name, fieldInfo.v, fieldInfo.isFinal, fieldInfo.get, fieldInfo.set);
                Reflect.setField(staticClass, fieldDecl.name, fieldInfo.v);
            }
        }

        if (!fieldDecls.exists('toString'))
        {
            staticFields.set('toString', () -> {return this.name;});
            staticInterp.forceVar('toString', () -> {return this.name;});
            Reflect.setField(staticClass, 'toString', () -> {return this.name;});
        }

        staticInterp.forceVar(name, staticClass, true);
        @:privateAccess module.interp.forceVar(name, staticClass, true);
    }

    public function s_new(?args:Array<Dynamic>):Dynamic
    {
        var instance:Dynamic = {};
        var fields:Map<String, Dynamic> = [];
        
        var superInstance:Dynamic = null;
        var superFieldsNames:Array<String> = [];

        if (args == null)
            args = [];

        var interp = new Interp();
        
        for (varName in staticInterp.listVars())
        {
            if ((!Interp.KEYWORDS.contains(varName) && !Interp.SPECIAL.contains(varName)) && !interp.hasVar(varName))
            {
                // trace('Adding old StaticField: "${varName}"');
                var varInfo:Dynamic = staticInterp.varInfo(varName);
                interp.forceVar(varName, staticInterp.resolve(varName), varInfo.isFinal, varInfo.getter, varInfo.setter);
            }
        }

        function createSuperInstance(args:Array<Dynamic>):Void
        {
            superInstance = Type.createInstance(superClass, args);

            for (superFieldName in Reflect.fields(superInstance).concat(Type.getInstanceFields(superClass)))
            {
                // trace('Adding SuperField: "${superFieldName}"');

                var superFieldValue:Dynamic = Reflect.getProperty(superInstance, superFieldName);
                interp.forceVar(superFieldName, superFieldValue);
                superFieldsNames.push(superFieldName);

                Reflect.setProperty(instance, superFieldName, superFieldValue);
            }

            interp.forceVar('super', superInstance, true);
        }

        function createScriptFunctions():Void
        {
            trace('${name}: Adding script functions');
        }

        function createFields():Void
        {
            for (fieldDecl in fieldDecls)
            {
                if ((!Interp.SPECIAL.contains(fieldDecl.name) && !fieldDecl.access.contains(AStatic)) && !Interp.KEYWORDS.contains(fieldDecl.name))
                {
                    if (!staticFields.exists(fieldDecl.name))
                    {
                        // trace('Adding Field: "${fieldDecl.name}"');

                        var fieldInfo:VarInfo = interp.field(fieldDecl);
                        interp.forceVar(fieldDecl.name, fieldInfo.v, fieldInfo.isFinal, fieldInfo.get, fieldInfo.set);
                        fields.set(fieldDecl.name, fieldInfo.v);

                        Reflect.setProperty(instance, fieldDecl.name, fieldInfo.v);
                    }
                    else 
                    {
                        FlxG.log.warn('Failed to add Field, "${fieldDecl.name}" already exists as a static field in "${this.name}"');
                    }
                }
            }
        }

        if (fieldDecls.exists('new'))
        {
            if (superClass != null)
            {
                interp.forceVar('super', Reflect.makeVarArgs(function(args:Array<Dynamic>) 
                {
                    createSuperInstance(args);
                }));
            }

            createFields();

            if (!fields.exists('toString'))
            {
                fields.set('toString', () -> {return this.name;});
                interp.forceVar('toString', () -> {return this.name;});
                Reflect.setField(instance, 'toString', () -> {return this.name;});
            }

            interp.forceVar('this', instance, true);
            Reflect.callMethod(instance, interp.field(fieldDecls.get('new')).v, args);
        }
        else
        {
            if (superClass != null)
            {
                createSuperInstance(args);
                createFields();
            }
            else
            {
                FlxG.log.warn('Failed to call ScriptClass Constructor, "${this.name}" does not have a constructor.');
            }
        }

        return superInstance;
    }

    public function s_staticSet(varName:String, varValue:Dynamic):Dynamic
    {
        if (staticFields.exists(varName))
        {
            if (!Reflect.isFunction(staticFields.get(varName)))
            {
                staticFields.set(varName, varValue);
                return varValue;
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
            return Reflect.callMethod(null, staticFields.get(funcName), funcArgs);
        
        FlxG.log.warn('Failed to Call Function for ScriptClass, "${this.name}" does not have the Function "${funcName}"');
        return null;
    }

    private function toString():String
    {
        if (staticFields.exists('toString'))
            return staticFields.get('toString')();

        return name;
    }
}