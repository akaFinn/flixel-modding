package flixel.util;

import haxe.io.Path;
import openfl.utils.Assets;
import flixel.system.hscript.FlxScript;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptEnum;
import flixel.system.hscript.FlxScriptInterface;
import flixel.system.hscript.FlxScriptTypedef;
import flixel.system.hscript.FlxScriptModule;

/**
 * A static class designed to help with scripting
 * in terms of normal scripts and scripted classes
 * 
 * @since 1.5.0
 */
@:access(flixel.system.hscript.FlxScriptClass)
@:access(flixel.system.hscript.FlxScriptEnum)
@:access(flixel.system.hscript.FlxScriptInterface)
@:access(flixel.system.hscript.FlxScriptTypedef)
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
     * Every script cached when using `buildAllScripts`
     * Key is usally the file path or package path to the class
     * 
     * You can cache a script using `FlxScriptUtil.addScript`
     */
    private static var cachedScripts:Map<String, FlxScript> = [];

    /**
     * Every script module cached when using `buildAllScriptModules`
     * Key is usally the file path or package path to the class
     * 
     * You can cache a script module using `FlxScriptUtil.addScriptModule`
     */
    private static var cachedScriptModules:Map<String, FlxScriptModule> = [];

    /**
     * Adds a script to the internal cache
     */
    public static function addScript(script:FlxScript):Void
    {
        @:privateAccess cachedScripts.set(script.origin, script);
    }

    /**
     * Gets a cached script by its origin/path
     */
    public static function getScript(path:String):FlxScript
    {
        if (FlxScriptUtil.cachedScripts.exists(path))
            return FlxScriptUtil.cachedScripts.get(path);

        FlxG.log.warn('Failed to get Script, "${path}" does not exist.');
        return null;
    }

    /**
     * Checks if a script exists in the cache by its origin/path
     */
     public static function hasScript(path:String):Bool
    {
        return FlxScriptUtil.cachedScripts.exists(path);
    }

    /**
     * Returns an array of all cached scripts
     */
    public static function listScripts():Array<FlxScript>
    {
        return Lambda.array(FlxScriptUtil.cachedScripts);
    }

    /**
     * Scans all embedded assets and builds/caches any script files found
     */
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

    /**
     * Adds a script module to the internal cache
     */
    public static function addScriptModule(scriptModule:FlxScriptModule):Void
    {
        @:privateAccess cachedScriptModules.set(scriptModule.origin, scriptModule);
    }

    /**
     * Gets a cached script module by its origin/path
     */
    public static function getScriptModule(path:String):FlxScriptModule
    {
        if (FlxScriptUtil.cachedScriptModules.exists(path))
            return FlxScriptUtil.cachedScriptModules.get(path);

        FlxG.log.warn('Failed to get ScriptModule, "${path}" does not exist.');
        return null;
    }

    /**
     * Checks if a script module exists in the cache by its origin/path
     */
    public static function hasScriptModule(path:String):Bool
    {
        return FlxScriptUtil.cachedScriptModules.exists(path);
    }

    /**
     * Returns an array of all cached script modules
     */
    public static function listScriptModules():Array<FlxScriptModule>
    {
        return Lambda.array(FlxScriptUtil.cachedScriptModules);
    }

    /**
     * Scans all embedded assets and builds/caches any script modules found
     */
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

    /**
     * Gets a script class by its name from all loaded modules
     */
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

    /**
     * Checks if a script class with the given name exists
     */
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

    /**
     * Returns an array of all script classes from all loaded modules
     */
    public static function listScriptClasses():Array<FlxScriptClass>
    {
        var result:Array<FlxScriptClass> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.classes));
        }

        return result;
    }

    /**
     * Returns an array of script classes that extend the given native class
     */
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

    /**
     * Gets a script enum by its name from all loaded modules
     */
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

    /**
     * Checks if a script enum with the given name exists
     */
    public static function hasScriptEnum(name:String):Bool
    {
        for (scriptEnum in FlxScriptUtil.listScriptEnums())
        {
            if (scriptEnum.name == name)
            {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns an array of all script enums from all loaded modules
     */
    public static function listScriptEnums():Array<FlxScriptEnum>
    {
        var result:Array<FlxScriptEnum> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.enums));
        }

        return result;
    }

    /**
     * Gets a script interface by its name from all loaded modules
     */
    public static function getScriptInterface(name:String):FlxScriptInterface
    {
        for (scriptInterface in FlxScriptUtil.listScriptInterfaces())
        {
            if (scriptInterface.name == name)
            {
                return scriptInterface;
            }
        }

        FlxG.log.warn('Failed to get ScriptInterface, "${name}" does not exist.');
        return null;
    }

    /**
     * Checks if a script interface with the given name exists
     */
    public static function hasScriptInterface(name:String):Bool
    {
        for (scriptInterface in FlxScriptUtil.listScriptInterfaces())
        {
            if (scriptInterface.name == name)
            {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns an array of all script interfaces from all loaded modules
     */
    public static function listScriptInterfaces():Array<FlxScriptInterface>
    {
        var result:Array<FlxScriptInterface> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.interfaces));
        }

        return result;
    }

    /**
     * Gets a script typedef by its name from all loaded modules
     */
    public static function getScriptTypedef(name:String):FlxScriptTypedef
    {
        for (scriptTypedef in FlxScriptUtil.listScriptTypedefs())
        {
            if (scriptTypedef.name == name)
            {
                return scriptTypedef;
            }
        }

        FlxG.log.warn('Failed to get ScriptTypedef, "${name}" does not exist.');
        return null;
    }

    /**
     * Checks if a script typedef with the given name exists
     */
    public static function hasScriptTypedef(name:String):Bool
    {
        for (scriptTypedef in FlxScriptUtil.listScriptTypedefs())
        {
            if (scriptTypedef.name == name)
            {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Returns an array of all script typedefs from all loaded modules
     */
    public static function listScriptTypedefs():Array<FlxScriptTypedef>
    {
        var result:Array<FlxScriptTypedef> = [];

        for (scriptModule in FlxScriptUtil.listScriptModules())
        {
            result = result.concat(Lambda.array(scriptModule.typedefs));
        }

        return result;
    }

    /**
     * Checks if the given file path is being used to cache a script or script module
     */
    public static function isFilePathScripted(path:String):Bool
    {
        return hasScript(path) || hasScriptModule(path);
    }

    /**
     * Checks if the given package path is being used for some kind of script
     */
    public static function isPackagePathScripted(pkg:Array<String>):Bool
    {
        var pkgName:String = pkg[pkg.length - 1];
        return hasScriptClass(pkgName) || hasScriptEnum(pkgName) || hasScriptInterface(pkgName) || hasScriptTypedef(pkgName);
    }
}