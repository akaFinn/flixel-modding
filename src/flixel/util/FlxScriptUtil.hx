package flixel.util;

#if hscript
import haxe.io.Path;
import flixel.system.hscript.FlxScriptModule;
import flixel.system.hscript.FlxScript;
import hscript.Interp;
import hscript.Tools;
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
	private static var defaultImports:Array<FlxModuleImport> = [];


	// TODO: Add a comment for this function
    public static function buildScript(origin:String, content:String, ?cache:Bool = true, ?key:String = ""):FlxScript
    {
		var script:FlxScript = null;
		var imports:Array<FlxModuleImport> = [];

        if (cachedScripts == null)
			cachedScripts = new Map<String, FlxScript>();

		script = new FlxScript(FlxScriptUtil.parseString(content, origin), imports);

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
		var packagePath:Array<String> = null;
		var scriptModule:FlxScriptModule = null;

		var imports:Map<String, FlxModuleImport> = [];
		var typedefs:Map<String, FlxTypeDecl> = [];
		var classes:Map<String, FlxClassDecl> = [];

		if (cachedScriptModules == null)
			cachedScriptModules = new Map<String, FlxScriptModule>();

		var module:Array<ModuleDecl> = FlxScriptUtil.parseModule(content, origin);

		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(path):
					packagePath = path;

				case DImport(path, everything):
					// TODO: Add support for importing scripted modules, 
					// should it check if the scripted one exists first? 
					// Yeah sure that works

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
					};

					var builtClass:Class<Dynamic> = Type.resolveClass(clsPath);
					var builtEnum:Enum<Dynamic> = Type.resolveEnum(clsPath);

					if (builtClass != null) importedModule.cls = builtClass;
					if (builtEnum != null) importedModule.enm = builtEnum;

					if (builtClass == null && builtEnum == null)
					{
						trace(clsPath);
					}

					imports.set(clsName, importedModule);

				case DClass(c):
					var superClass:Null<CType> = c.extend;

					if (superClass != null)
					{
						var superClassPath:Array<String> = new Printer().typeToString(superClass).split(".");
						var superClassName:String = superClassPath[superClassPath.length - 1];

						if (imports.exists(superClassName))
						{
							var superClassImport = imports.get(superClassName);

							if (superClassImport.cls == null)
							{
								FlxG.log.warn("Could not import super class due to it not being imported before hand");
							}
							
							switch (superClass)
							{
								case CTPath(path, params):
									superClass = CTPath(superClassPath, params);
								default:
									// TODO: Add more support?
							}
						}
					}

					var classDecl:FlxClassDecl =
					{
						name: c.name,
						meta: c.meta,
						fields: c.fields,
						params: c.params,
						extend: c.extend,
						isPrivate: c.isPrivate,
						isExtern: c.isExtern,
						implement: c.implement,
						imports: imports,
						pkg: packagePath,
					}

					classes.set(classDecl.name, classDecl);

				case DTypedef(c):
					var typeDecl:FlxTypeDecl = 
					{
						t: c.t,
						name: c.name,
						meta: c.meta,
						params: c.params,
						isPrivate: c.isPrivate,
						imports: imports,
						pkg: packagePath,
					}

					typedefs.set(typeDecl.name, typeDecl);
			}
		}

		scriptModule = new FlxScriptModule(classes, typedefs, packagePath);
		
		if (cache != false)
		{
			if (key == null || key == "")
				key = origin;

			cachedScriptModules.set(FlxScriptUtil.filePathToPackagePath(key).join("."), scriptModule);
		}

		return scriptModule;
	}

	/**
	 * Parses the contents of a script and converts it into an `Expr`
	 * 
	 * @param   content   The content that will get parsed
	 * @param   origin    (Optional) the origin of the content
	 * 
	 * @return  The converted `Expr`
	 */
	public static function parseString(content:String, ?origin:String = FlxScriptUtil.DEFAULT_SCRIPT_ORIGIN):Expr
	{
		return FlxScriptUtil.parser.parseString(content, origin);
	}

	/**
	 * Parses the contents of a script module and converts it into an array of `ModuleDecl`'s
	 * 
	 * @param   content   The content that will get parsed
	 * @param   origin    (Optional) the origin of the content
	 * 
	 * @return  The converted array of `ModuleDecl`'s
	 */
	public static function parseModule(content:String, ?origin:String = FlxScriptUtil.DEFAULT_SCRIPT_ORIGIN):Array<ModuleDecl>
	{
		return FlxScriptUtil.parser.parseModule(content, origin);
	}

	/**
	 * Adds a default `FlxModuleImport` to the default imports variable,
	 * which can then be used when building an interpreter
	 * 
	 * @param   value   The `FlxModuleImport` that your adding
	 */
	public static function addDefaultImport(value:FlxModuleImport):Void
	{
		FlxScriptUtil.defaultImports.push(value);
	}

	/**
	 * Removes a `FlxModuleImport` from the default imports variable
	 * 
	 * @param   value   The `FlxModuleImport` that your removing
	 */
	public static function removeDefaultImport(value:FlxModuleImport):Void
	{
		FlxScriptUtil.defaultImports.remove(value);
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

		#if sys
		interp.variables.set("Sys", Sys);
		#end

		for (defaultImport in defaultImports)
		{
			var builtClass:Class<Dynamic> = defaultImport.cls;
			var builtEnum:Enum<Dynamic> = defaultImport.enm;

			if (builtClass != null) 
				interp.variables.set(defaultImport.name, builtClass);
			
			if (builtEnum != null) 
				interp.variables.set(defaultImport.name, builtEnum);
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
		/*
			Why don't you help them, you double-dealing manipulator?

			What's in it for me?
			I don't work for free
			You want help, well, you know the fee

			I will not reward a snake like you

			You'll watch them die unless you do

			Liar, you wouldn't dare

			Quid pro quo, it's only fair

			You really are a demon, pet

			You knew my game the day we met
		*/

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
	@:optional var pkg:Array<String>;
	@:optional var cls:Class<Dynamic>;
	@:optional var enm:Enum<Dynamic>;
}

/**
 * Represents a typedef declaration parsed from a script module.
 * 
 * Stores the base hscript `TypeDecl` data along with any extra
 * metadata, parameters, imports, and the typedef's package path.
 */
typedef FlxTypeDecl = 
{
    > TypeDecl,

    @:optional var pkg:Array<String>;
    @:optional var imports:Map<String, FlxModuleImport>;
}

/**
 * Represents a full class declaration parsed from a script module.
 * 
 * Contains all the information needed to recreate or register a
 * scripted class: fields, params, metadata, inheritance, imports,
 * and the class's package path.
 */
typedef FlxClassDecl = 
{
    > ClassDecl,

    @:optional var pkg:Array<String>;
    @:optional var imports:Map<String, FlxModuleImport>;
}
#end