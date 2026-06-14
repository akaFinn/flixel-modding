package flixel.system.hscript;

import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptTypedef implements IFlxScriptModuleType
{
    public var pkg(get, never):Array<String>;

    function get_pkg():Array<String>
    {
        if (module.name == this.name)
            return module.pkg;

        var pkgClone:Array<String> = module.pkg.copy();
        pkgClone.push(module.name);
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

    var interp:Interp;

    var module:FlxScriptModule;

    var decl:TypeDecl;

    public function new(module:FlxScriptModule, decl:TypeDecl)
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
        return 'FlxScriptTypedef<${name}>';
    }
}