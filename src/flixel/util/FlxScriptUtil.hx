package flixel.util;

#if hscript
import haxe.io.Path;
import flixel.system.hscript.FlxScriptTypedef;
import flixel.system.hscript.FlxScriptClass;
import flixel.system.hscript.FlxScriptModule;
import flixel.system.hscript.FlxScript;
import hscript.Interp;
import hscript.Parser;
import hscript.Printer;
import hscript.Expr;

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
	public static var cachedScripts:Map<String, FlxScript>;

	/**
	 * Every script module cached when using `buildScriptModule`
	 * Key is usally the file path or package path to the class
	 * 
	 * You can cache a script module using `FlxScriptUtil.buildScriptModule`
	 */
	public static var cachedScriptModules:Map<String, FlxScriptModule>;

	/**
	 * Static interpreter used for running code
	 */	
    private static var interp:Interp = FlxScriptUtil.buildInterp();

	/**
	 * Static parser used for parsing code
	 */	
    private static var parser:Parser = FlxScriptUtil.buildParser();

	/**
	 * The default imports that get added to the interpreter
	 * when one is built using `FlxScriptUtil.buildInterp()`
	 */
	public static var defaultImports:Array<FlxModuleImport> = [];

	// TODO: Add a comment for this function
    public static function buildScript(origin:String, content:String, ?cache:Bool = true, ?key:String = ""):FlxScript
    {
		var script:FlxScript = null;
		var imports:Array<FlxModuleImport> = [];

        if (cachedScripts == null)
			cachedScripts = new Map<String, FlxScript>();

		var expr:Expr = FlxScriptUtil.buildParser().parseString(content, origin);

		script = new FlxScript(origin, expr, imports);

		if (cache != false)
		{
			if (key == null || key == "")
				key = origin;

			cachedScripts.set(key, script);
		}

		return script;
    }

	/**
	 * A static function that takes the content of a script module
	 * and converts it into a fully functional `FlxScriptModule`
	 * using good ol' hscript just like god intended.
	 * 
	 * Heavly based on polymod's & rulescript's respective backends, love em both <3.
	 * 
	 * @param   origin    The origin of where the content's came from e.g. `assets/data/ScriptModule.hxc`
	 * @param   content   The content for the script module that will be parsed & interpreted
	 * @param   cache     (Optional) Weither or not you want the built script module to be cached in `cachedScriptModules`
	 * @param   key       (Optional) The key that'll be used when caching the script module IF `cache` is set to true
	 * 
	 * @return  A built script module
	 */
	public static function buildScriptModule(origin:String, content:String, ?cache:Bool = true, ?key:String = ""):FlxScriptModule
	{
		var packagePath:Array<String> = FlxScriptUtil.filePathToPackagePath(origin);
		var scriptModule:FlxScriptModule = null;

		var imports:Map<String, FlxModuleImport> = [];
		var typedefs:Map<String, TypeDecl> = [];
		var classes:Map<String, ClassDecl> = [];

		if (cachedScriptModules == null)
			cachedScriptModules = new Map<String, FlxScriptModule>();

		var module:Array<ModuleDecl> = FlxScriptUtil.buildParser().parseModule(content, origin);

		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(path):
					var newPath:Array<String> = path;
					newPath.push(packagePath[packagePath.length - 1]);

					packagePath = newPath;

				case DImport(path, everything):
					var clsName:String = path[path.length - 1];
					var clsPath:String = path.join(".");

					var clsPkg:Array<String> = path.slice(0, path.length - 1);

					var importedModule:FlxModuleImport = 
					{
						name: clsName,
						path: clsPath,
						pkg: clsPkg,

						cls: null,
						enm: null,
						
						dyn: null,
					};

					// TODO: Add support for also grabbing scripted classes and not just the module
					// TODO: Add support for grabbing every module found within a path via that `everything` parameter

					switch (everything)
					{
						case true:
							// TODO: Yeah get this working

						case false:
							if (FlxScriptUtil.cachedScriptModules.exists(clsPath))
							{
								var module:FlxScriptModule = cachedScriptModules.get(clsPath);

								var scriptClass:FlxScriptClass = module.classes.get(clsName);
								var scriptTypedef:FlxScriptTypedef = module.typedefs.get(clsName);

								if (scriptClass != null && !scriptClass.decl.isPrivate)
								{
									var staticScriptClass:Dynamic = {};

									for (field in scriptClass.decl.fields)
									{
										if (field.access.contains(FieldAccess.AStatic) && field.access.contains(FieldAccess.APublic))
										{
											Reflect.setField(staticScriptClass, field.name, scriptClass.convertFieldDecl(field));
										}
									}

									importedModule.dyn = staticScriptClass;
								}
								else if (scriptTypedef != null && !scriptTypedef.decl.isPrivate)
								{
									// TODO: Finish this
								}
								else
								{
									FlxG.log.warn("Failed to import script module, could not find class nor typedef.");
								}
							}
							else
							{
								var builtClass:Class<Dynamic> = Type.resolveClass(clsPath);
								var builtEnum:Enum<Dynamic> = Type.resolveEnum(clsPath);

								if (builtClass != null) importedModule.cls = builtClass;
								if (builtEnum != null) importedModule.enm = builtEnum;
							} 
					}

					imports.set(clsName, importedModule);

				case DClass(c):
					classes.set(c.name, c);

				case DTypedef(c):
					typedefs.set(c.name, c);
			}
		}

		scriptModule = new FlxScriptModule(origin, classes, typedefs, imports, packagePath);
		
		if (cache != false)
		{
			if (key == null || key == "")
				key = packagePath.join(".");

			cachedScriptModules.set(key, scriptModule);
		}

		return scriptModule;
	}

	/**
	 * Calls a function inside a scripted module's class.
	 * 
	 * @param   moduleKey    The name/key of the module that was cached
	 * @param   clsName    The class inside the module where the function exists
	 * 
	 * @param   funcName   The name of the function being called
	 * @param   funcArgs   (Optional) Arguments that will be passed to the function
	 * 
	 * @return  The returned value from the scripted function, or null if the module does not exist
	 */
	public static function callFunction(moduleKey:String, clsName:String, funcName:String, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		if (cachedScriptModules.exists(moduleKey))
		{
			return cachedScriptModules[moduleKey].callFunction(clsName, funcName, funcArgs);
		}
		else
		{
			FlxG.log.warn('Cannot access module: "$moduleKey" as the module does not exist.');
		}
		
		return null;
	}

	/**
	 * Retrieves a variable from a scripted module's class.
	 * 
	 * @param   moduleKey     The name/key of the module that was cached
	 * @param   clsName     The class inside the module where the variable exists
	 * 
	 * @param   varName     The variable name being retrieved
	 * @param   varStatic   (Optional) If true, grabs a static variable; otherwise grabs an instance variable
	 * 
	 * @return  The variable's value, or null if the module does not exist
	 */
	public static function getVariable(moduleKey:String, clsName:String, varName:String, ?varStatic:Bool = true):Dynamic
	{
		if (cachedScriptModules.exists(moduleKey))
		{
			return cachedScriptModules[moduleKey].getVariable(clsName, varName, varStatic);
		}
		else
		{
			FlxG.log.warn('Cannot access module: "$moduleKey" as the module does not exist.');
		}
		
		return null;
	}

	/**
	 * Sets a variable inside a scripted module's class.
	 * 
	 * @param   moduleKey     The name/key of the module that was cached
	 * @param   clsName     The class inside the module where the variable exists
	 * 
	 * @param   varName     The variable name being modified
	 * @param   varValue    The new value to assign to the variable
	 * @param   varStatic   (Optional) If true, modifies a static variable; otherwise an instance variable
	 */
	public static function setVariable(moduleKey:String, clsName:String, varName:String, varValue:Dynamic, ?varStatic:Bool = true):Void
	{
		if (cachedScriptModules.exists(moduleKey))
		{
			cachedScriptModules[moduleKey].setVariable(clsName, varName, varValue, varStatic);
		}
		else
		{
			FlxG.log.warn('Cannot access module: "$moduleKey" as the module does not exist.');
		}
	}

	/**
	 * Grabs every scripted class across all cached modules that directly
	 * extends the given Haxe class.
	 * 
	 * @param   cls   The class type being checked against scripted classes
	 * 
	 * @return  An array of `FlxScriptClass` entries whose superclass matches `cls`
	 */
	public static function getClassesExtending(cls:Class<Dynamic>):Array<FlxScriptClass>
	{
		var result:Array<FlxScriptClass> = [];
		
		for (scriptModule in cachedScriptModules)
		{
			for (scriptClass in scriptModule.classes)
			{
				if (scriptClass.superClass == cls)
				{
					result.push(scriptClass);
				}
			}
		}

		return result;
	}

	public static function reloadScript(key:String):Void
	{
		if (FlxScriptUtil.cachedScripts.exists(key))
		{
			
		}
	}

    /**
     * Builds a default `Parser` for hscript
	 * 
     * @return The `Parser`
     */
    private static function buildParser():Parser
    {
        var parser:Parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;
		parser.allowMetadata = true;

        return parser;
    }

	/**
     * Builds a default `Interp` for hscript
	 * 
     * @return The `Interp`
     */
    private static function buildInterp():Interp
    {
        var interp:Interp = new Interp();

		interp.variables.set("Std", Std);
		interp.variables.set("Math", Math);

		interp.variables.set("Type", Type);
		interp.variables.set("Date", Date);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("DateTools", DateTools);
		interp.variables.set("Lambda", Lambda);

		#if sys
		interp.variables.set("Sys", Sys);
		#end

		if (defaultImports != null)
		{
			for (defaultImport in defaultImports)
			{
				var builtClass:Class<Dynamic> = defaultImport.cls;
				var builtEnum:Enum<Dynamic> = defaultImport.enm;
				var buildDynamic:Dynamic = defaultImport.dyn;

				if (builtClass != null) 
					interp.variables.set(defaultImport.name, builtClass);

				if (builtEnum != null) 
					interp.variables.set(defaultImport.name, builtEnum);

				if (buildDynamic != null) 
					interp.variables.set(defaultImport.name, buildDynamic);
			}
		}

        return interp;
    }

	/**
	 * Takes a file path and converts it to a package path
	 * 
	 * @param   path   The file path that'll get converted
	 * 
	 * @return  The converted package path
	 */
	private static function filePathToPackagePath(path:String):Array<String>
	{
		return Path.withoutExtension(path).split("/");
	}

	/**
	 * Takes the path of a package aka an array of strings and turns it into a file path
	 * 
	 * @param   pkg   The package that'll get converted
	 * @param   ext   (Optional) The file extension that'll be put at the end of the given file path
	 * 
	 * @return  The converted file path
	 */
	private static function packagePathToFilePath(pkg:Array<String>, ?ext:String):String
	{
		if (ext == null)
		{
			var exts:Array<String> = grabEveryFileExtension();
			ext = exts[FlxG.random.int(0, exts.length - 1)];
		}

		return pkg.join("/") + "." + ext;
	}

	/**
	 * Grabs an array of every file extension used for scripts
	 * 
	 * @return The array of file extensions
	 */
	private static function grabEveryFileExtension():Array<String>
	{
		return HAXE_FILE_EXTS.concat(MODULE_FILE_EXTS).concat(SCRIPT_FILE_EXTS);
	}
}

/**
 * Represents information about an imported class or enum.
 * 
 * Used when parsing script modules to keep track of
 * every import declared inside the module.
 */
typedef FlxModuleImport =
{
    var name:String;
    var path:String;
	var pkg:Array<String>;

	@:optional var cls:Class<Dynamic>;
	@:optional var enm:Enum<Dynamic>;

	@:optional var dyn:Dynamic;
}
#end