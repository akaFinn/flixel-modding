package flixel.system.hscript;

import flixel.system.macros.FlxScriptMacro;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

class FlxScriptClass
{
    public var name:String;

    public var isPrivate:Bool;

    public var isExtern:Bool;

    public var superClass:Class<Dynamic>;

    var staticFields:Map<String, Dynamic> = [];

    var staticInterp:Interp;

    var staticClass:Dynamic;
    
    var fieldDecls:Map<String, FieldDecl> = [];

    var module:FlxScriptModule;

    var decl:ClassDecl;

    public function new(module:FlxScriptModule, decl:ClassDecl)
    {
        this.module = module;
        this.decl = decl;

        staticInterp = new Interp();
        
        @:privateAccess
        for (varName in module.interp.variables.keys())
        {
            if (!staticInterp.variables.exists(varName))
                staticInterp.variables.set(varName, module.interp.variables.get(varName));
        }

        name = decl.name;
        isPrivate = decl.isPrivate;
        isExtern = decl.isExtern;
        
        if (decl.extend != null)
        {
            switch (decl.extend)
            {
                case CTPath(path, _):
                    var fullPath:String = path.join(".");

                    if (staticInterp.variables.exists(fullPath))
                        superClass = staticInterp.variables.get(fullPath);
                    else 
                        superClass = Type.resolveClass(fullPath);

                default:
            }
        }

        staticClass = {};

        for (fieldDecl in decl.fields)
        {
            fieldDecls.set(fieldDecl.name, fieldDecl);

            if (fieldDecl.access.contains(AStatic) && !Interp.KEYWORDS.contains(fieldDecl.name))
            {
                // trace('Adding StaticField: "${fieldDecl.name}"');

                var fieldValue:Dynamic = staticInterp.field(fieldDecl);

                staticFields.set(fieldDecl.name, fieldValue);
                staticInterp.variables.set(fieldDecl.name, fieldValue);
                Reflect.setField(staticClass, fieldDecl.name, fieldValue);
            }
        }

        if (!fieldDecls.exists('toString'))
        {
            staticFields.set('toString', () -> {return this.name;});
            staticInterp.variables.set('toString', () -> {return this.name;});
            Reflect.setField(staticClass, 'toString', () -> {return this.name;});
        }

        staticInterp.variables.set(name, staticClass);
        @:privateAccess module.interp.variables.set(name, staticClass);
    }

    public function scriptNew(?args:Array<Dynamic>):Dynamic
    {
        var instance:Dynamic = {};
        var fields:Map<String, Dynamic> = [];
        
        var superInstance:Dynamic = null;
        var superFieldsNames:Array<String> = [];

        if (args == null)
            args = [];

        var interp = new Interp();
        
        for (varName in staticInterp.variables.keys())
        {
            if ((!Interp.KEYWORDS.contains(varName) && !Interp.SPECIAL.contains(varName)) && !interp.variables.exists(varName))
            {
                // trace('Adding old StaticField: "${varName}"');
                interp.variables.set(varName, staticInterp.variables.get(varName));
            }
        }

        function createSuperInstance(args:Array<Dynamic>):Void
        {
            superInstance = Type.createInstance(superClass, args);

            for (superFieldName in Reflect.fields(superInstance).concat(Type.getInstanceFields(superClass)))
            {
                // trace('Adding SuperField: "${superFieldName}"');

                var superFieldValue:Dynamic = Reflect.field(superInstance, superFieldName);
                interp.variables.set(superFieldName, superFieldValue);
                superFieldsNames.push(superFieldName);

                Reflect.setField(instance, superFieldName, superFieldValue);
            }

            interp.variables.set('super', superInstance);
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

                        var fieldValue:Dynamic = interp.field(fieldDecl);
                        interp.variables.set(fieldDecl.name, fieldValue);
                        fields.set(fieldDecl.name, fieldValue);

                        Reflect.setField(instance, fieldDecl.name, fieldValue);
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
                interp.variables.set('super', Reflect.makeVarArgs(function(args:Array<Dynamic>) 
                {
                    createSuperInstance(args);
                }));
            }

            createFields();

            if (!fields.exists('toString'))
            {
                fields.set('toString', () -> {return this.name;});
                interp.variables.set('toString', () -> {return this.name;});
                Reflect.setField(instance, 'toString', () -> {return this.name;});
            }

            interp.variables.set('this', instance);
            Reflect.callMethod(instance, interp.field(fieldDecls.get('new')), args);
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

    public function scriptStaticSet(varName:String, varValue:Dynamic):Void
    {
        if (Reflect.hasField(staticClass, varName))
            Reflect.setField(staticClass, varName, varValue);
        else
            FlxG.log.warn('Failed to Set Variable for ScriptClass, "${this.name}" does not have the Variable "${varName}"');
    }

    public function scriptStaticGet(varName:String):Dynamic
    {
        if (Reflect.hasField(staticClass, varName))
            return Reflect.field(staticClass, varName);
        else
        {
            FlxG.log.warn('Failed to Get Variable for ScriptClass, "${this.name}" does not have the Variable "${varName}"');
            return null;
        }
    }

    public function scriptStaticCall(funcName:String, funcArgs:Array<Dynamic>):Dynamic
    {
        if (Reflect.hasField(staticClass, funcName))
            return Reflect.callMethod(staticClass, Reflect.field(staticClass, funcName), funcArgs);
        else
        {
            FlxG.log.warn('Failed to Call Function for ScriptClass, "${this.name}" does not have the Function "${funcName}"');
            return null;
        }
    }

    private function toString():String
    {
        if (staticFields.exists('toString'))
            return staticFields.get('toString')();

        return name;
    }
}