package flixel.system.hscript;

import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptInterface implements IFlxScriptModuleType
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

    public var isExtern(get, never):Bool;
    
    function get_isExtern():Bool
    {
        return this.decl.isExtern;
    }

    var interp:Interp;

    var module:FlxScriptModule;

    var decl:InterfaceDecl;

    public function new(module:FlxScriptModule, decl:InterfaceDecl)
    {
        this.module = module;
        this.decl = decl;

        interp = module.interp.copy();
    }

    public function getScriptObj():Dynamic
    {
        return null;
    }

    private function toString():String
    {
        return 'FlxScriptInterface<${name}>';
    }
}