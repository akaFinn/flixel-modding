package flixel.system.polymod;

import haxe.io.Path; 
import flixel.util.FlxScriptUtil; 
import openfl.utils.Assets; 

#if polymod 
import polymod.hscript._internal.PolymodScriptClass; 
#end


/**
 * Provides integration helpers for building and registering
 * Polymod-based scripted classes within the engine.
 *
 * This class bridges embedded TEXT assets and Polymod’s internal
 * script class registration system.
 *
 * When the `polymod` compile flag is disabled, all operations
 * gracefully fall back to warning logs, allowing the engine
 * to function without Polymod installed.
 */
class PolymodScripting
{
    /**
     * Builds and registers all scripted classes discovered in embedded text assets.
     *
     * When the `polymod` compile flag is enabled, this method:
     * - Iterates through all embedded TEXT assets
     * - Filters them using `FlxScriptUtil.MODULE_FILE_EXTS`
     * - Registers matching files via `buildFromPath`
     *
     * If Polymod is not installed or not enabled at compile time,
     * a warning is logged and no scripts are processed.
     */
    public static function buildAllScriptedClasses():Void
    {
        #if polymod
        for (textPath in Assets.list(TEXT))
        {
            if (FlxScriptUtil.MODULE_FILE_EXTS.contains(Path.extension(textPath)))
            {
                PolymodScripting.buildFromPath(textPath);
            }
        }
        #else
        FlxG.log.warn('Failed to build scripted classes, polymod is not installed.');
        #end
    }

    /**
     * Registers a scripted class directly from raw script content.
     *
     * This forwards the provided script string to Polymod’s internal
     * script class registry using `@:privateAccess`.
     *
     * If the `polymod` flag is not defined, a warning is logged instead.
     *
     * @param content The full script source to register as a class.
     */
    private static function buildFromString(content:String):Void
    {
        #if polymod
        @:privateAccess PolymodScriptClass.registerScriptClassByString(content);
        #else
        FlxG.log.warn('Failed to build from string, polymod is not installed.');
        #end
    }

    /**
     * Registers a scripted class from a filesystem path.
     *
     * Behavior:
     * - Verifies the file exists before attempting to read it
     * - Reads the file contents
     * - Registers the script with Polymod’s internal class registry
     *
     * If the file does not exist or Polymod is unavailable,
     * a warning is logged.
     *
     * @param path The filesystem path to the script file.
     */
    private static function buildFromPath(path:String):Void
    {
        #if polymod
        @:privateAccess
        {
            if (FlxFileSystem.exists(path))
            {
                PolymodScriptClass.registerScriptClassByString(FlxFileSystem.getFileContent(path), path);
            }
            else
            {
                FlxG.log.warn('Failed to build from path, file path does not exist.');
            }
        }
        #else
        FlxG.log.warn('Failed to build from path, polymod is not installed.');
        #end
    }
}