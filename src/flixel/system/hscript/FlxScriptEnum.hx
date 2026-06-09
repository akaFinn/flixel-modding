package flixel.system.hscript;

import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptEnum implements IFlxScriptReference
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

    var interp:Interp;

    var module:FlxScriptModule;

    var decl:EnumDecl;

    public function new(module:FlxScriptModule, decl:EnumDecl)
    {
        this.module = module;
        this.decl = decl;

        interp = module.interp.copy();
    }

    public function s_createAll():Array<FlxScriptEnumValue>
    {
        var result:Array<FlxScriptEnumValue> = [];

        var index:Int = 0;
        for (fieldDecl in decl.fields)
        {
            result.push(new FlxScriptEnumValue(fieldDecl));
            index++;
        }

        return result;
    }

    public function s_createByIndex(index:Int):FlxScriptEnumValue
    {
        if (decl.fields[index] != null)
            return new FlxScriptEnumValue(decl.fields[index]);

        FlxG.log.warn('Failed to Create ScriptEnumValue by Index, ${index} does not exist in ScriptEnum "${this.name}"');
        return null;
    }

    public function s_createByName(name:String):FlxScriptEnumValue
    {
        var index:Int = 0;
        for (fieldDecl in decl.fields)
        {
            if (fieldDecl.name == name)
            {
                return new FlxScriptEnumValue(fieldDecl);
            }

            index++;
        }

        FlxG.log.warn('Failed to Create ScriptEnumValue by Name, "${name}" does not exist in ScriptEnum "${this.name}"');
        return null;
    }

    public function s_getConstructors():Array<String>
    {
        var result:Array<String> = [];

        for (fieldDecl in decl.fields)
        {
            result.push(fieldDecl.name);
        }

        return result;
    }

    public function s_getName():String
    {
        return this.name;
    }

    private function toString():String
    {
        return 'FlxScriptEnum<${name}>';
    }
}

private class FlxScriptEnumValue
{
    var decl:EnumFieldDecl;

    public function new(decl:EnumFieldDecl)
    {
        this.decl = decl;
    }

    public function s_getName():String
    {
        return decl.name;
    }
}