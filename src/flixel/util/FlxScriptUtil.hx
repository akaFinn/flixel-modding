package flixel.util;

import flixel.system.hscript.FlxScriptEnum;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.system.hscript.FlxScript;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptModule;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

/**
 * A static class designed to help with scripting
 * in terms of normal scripts and scripted classes
 * 
 * @since 1.5.0
 */
class FlxScriptUtil
{
    /**
     * File extension for basic scripts
     */	
    public static var SCRIPT_FILE_EXTS:Array<String> = ["hxs", "hscript"];

    /**
     * File extension for script modules
     */	
    public static var MODULE_FILE_EXTS:Array<String> = ["hxc", "hxm", "hclass", "hmodule"];

    /**
     * File extension for haxe files
     */	
    public static var HAXE_FILE_EXTS:Array<String> = ["hx"];

    /**
     * Default prefix used for identifying scripted classes that want to replace the source code
     */	
    public static inline var DEFAULT_SOURCE_PREFIX:String = "_source";

    /**
     * The default origin string used for scripts
     */
    public static inline var DEFAULT_SCRIPT_ORIGIN:String = "hscript";

    /**
     * Every script cached when using `buildScript`
     * Key is usally the file path or package path to the class
     * 
     * You can cache a script using `FlxScriptUtil.buildScript`
     */
    private static var cachedScripts:Map<String, FlxScript> = [];

    /**
     * Every script module cached when using `buildScriptModule`
     * Key is usally the file path or package path to the class
     * 
     * You can cache a script module using `FlxScriptUtil.buildScriptModule`
     */
    private static var cachedScriptModules:Map<String, FlxScriptModule> = [];

    /**
     * The default imports that get added to the interpreter
     * when one is built using `FlxScriptUtil.buildInterp()`
     */
    // private static var defaultImports:Array<FlxModuleImport> = [];

    public static function addScript(script:FlxScript):Void
    {
        @:privateAccess cachedScripts.set(script.origin, script);
    }

    public static function getScript(path:String):FlxScript
    {
        if (FlxScriptUtil.cachedScripts.exists(path))
            return FlxScriptUtil.cachedScripts.get(path);

        FlxG.log.warn('Failed to get Script, "${path}" does not exist.');
        return null;
    }

    public static function listScripts():Array<FlxScript>
    {
        return Lambda.array(FlxScriptUtil.cachedScripts);
    }

    public static function buildAllScripts():Void
    {
        for (path in Assets.list(TEXT))
        {
            if (SCRIPT_FILE_EXTS.contains(Path.extension(path)))
            {
                var script:FlxScript = new FlxScript(path);
                FlxScriptUtil.addScript(script);
            }
        }
    }

    public static function addScriptModule(scriptModule:FlxScriptModule):Void
    {
        @:privateAccess cachedScriptModules.set(scriptModule.origin, scriptModule);
    }

    public static function getScriptModule(path:String):FlxScriptModule
    {
        if (FlxScriptUtil.cachedScriptModules.exists(path))
            return FlxScriptUtil.cachedScriptModules.get(path);

        FlxG.log.warn('Failed to get ScriptModule, "${path}" does not exist.');
        return null;
    }

    public static function hasScriptModule(path:String):Bool
    {
        return FlxScriptUtil.cachedScriptModules.exists(path);
    }

    public static function listScriptModules():Array<FlxScriptModule>
    {
        return Lambda.array(FlxScriptUtil.cachedScriptModules);
    }

    public static function buildAllScriptModules():Void
    {
        for (path in Assets.list(TEXT))
        {
            if (MODULE_FILE_EXTS.concat(HAXE_FILE_EXTS).contains(Path.extension(path)))
            {
                var module:FlxScriptModule = new FlxScriptModule(path);
                FlxScriptUtil.addScriptModule(module);
            }
        }
    }

    public static function getScriptClass(name:String):FlxScriptClass
    {
        for (scriptClass in FlxScriptUtil.listScriptClasses())
        {
            if (scriptClass.name == name)
            {
                return scriptClass;
            }
        }

        FlxG.log.warn('Failed to get ScriptClass, "${name}" does not exist.');
        return null;
    }

    public static function hasScriptClass(name):Bool
    {
        for (scriptClass in FlxScriptUtil.listScriptClasses())
        {
            if (scriptClass.name == name)
            {
                return true;
            }
        }

        return false;
    }

    public static function listScriptClasses():Array<FlxScriptClass>
    {
        var result:Array<FlxScriptClass> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.classes));
        }

        return result;
    }

    public static function getScriptEnum(name:String):FlxScriptEnum
    {
        for (scriptEnum in FlxScriptUtil.listScriptEnums())
        {
            if (scriptEnum.name == name)
            {
                return scriptEnum;
            }
        }

        FlxG.log.warn('Failed to get ScriptEnum, "${name}" does not exist.');
        return null;
    }

    public static function listScriptEnums():Array<FlxScriptEnum>
    {
        var result:Array<FlxScriptEnum> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.enums));
        }

        return result;
    }

    public static function listScriptClassesExtending(cls:Class<Dynamic>):Array<FlxScriptClass>
    {
        var result:Array<FlxScriptClass> = [];

        for (scriptClass in FlxScriptUtil.listScriptClasses())
        {
            if (scriptClass.superClass == cls)
            {
                result.push(scriptClass);
            }
        }

        return result;
    }
}