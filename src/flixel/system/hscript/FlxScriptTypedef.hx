package flixel.system.hscript;

import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptTypedef
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

    var interp:Interp;

    var module:FlxScriptModule;

    var decl:TypeDecl;

    public function new(module:FlxScriptModule, decl:TypeDecl)
    {
        this.module = module;
        this.decl = decl;

        interp = module.interp.copy();
    }
}