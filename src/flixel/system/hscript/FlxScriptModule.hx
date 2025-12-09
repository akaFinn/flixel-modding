package flixel.system.hscript;

#if hscript
import flixel.util.FlxStringUtil;
import flixel.util.FlxScriptUtil;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr.ClassDecl;
import hscript.Expr.TypeDecl;

/**
 * A class designed for scripted modules
 * its holds both classes & typedefs
 * 
 * @since 1.6.0
 */
@:access(flixel.util.FlxScriptUtil)
class FlxScriptModule extends FlxBasic
{
	/**
	 * The package path of the script module, if one was provided.
	 * Represents the module's logical location inside the project.
	 */
	var pkgPath:Array<String> = [];

	/**
	 * A map containing two interpreters:
	 * one used for static access and one used for instance access.
	 * Keys are `true` and `false` (as strings).
	 */
    var interp:Map<String, Interp>;

	/**
	 * Origin of the script
	 */
	var origin:String;

	/**
	 * Every scripted class parsed from the module.
	 * The key is the class name, and the value is its runtime wrapper.
	 */
	public var classes:Map<String, FlxScriptClass>;

	/**
	 * Every typedef parsed from the module.
	 * Stored as runtime-friendly wrappers for lookup and execution.
	 */
	public var typedefs:Map<String, FlxScriptTypedef>;

	/**
	 * Every import added from the module.
	 * Stores the class/enum, package path, and name.
	 */
	public var imports:Map<String, FlxModuleImport> = [];

	/**
	 * Constructs a new script module from parsed class & typedef declarations.
	 * 
	 * @param   scriptOrigin    The origin of the script
	 * 
	 * @param   classDecls      All parsed class declarations
	 * @param   typeDecls       All parsed typedef declarations
	 * 
	 * @param   moduleImports   All parsed module imports
	 * @param   pkg             The module's package path
	 */
    public function new(scriptOrigin:String, classDecls:Map<String, ClassDecl>, typeDecls:Map<String, TypeDecl>, moduleImports:Map<String, FlxModuleImport>, pkg:Array<String>)
    {
		pkgPath = pkg;
		origin = scriptOrigin;

		interp = new Map<String, Interp>();
		interp.set("true", FlxScriptUtil.buildInterp());
		interp.set("false", FlxScriptUtil.buildInterp());

		imports = moduleImports;
		classes = new Map<String, FlxScriptClass>();
		typedefs = new Map<String, FlxScriptTypedef>();

        super();

		for (moduleImport in moduleImports) addImport(moduleImport);

		for (classDecl in classDecls) classes.set(classDecl.name, new FlxScriptClass(classDecl, this));
		for (typeDecl in typeDecls) typedefs.set(typeDecl.name, new FlxScriptTypedef(typeDecl, this));
    }

	/**
	 * The previously accessed class name.
	 * Used to detect class changes and force field reloads.
	 */
	var prevClsName:String = "";

	/**
	 * Calls a function on a scripted class.
	 * Reloads fields on class-change to ensure accuracy.
	 * 
	 * @param clsName    The class name to call on
	 * @param funcName   The function to invoke
	 * @param funcArgs   (Optional) Arguments passed to the function
	 * 
	 * @return Whatever the script function returns, or null if invalid
	 */
	public function callFunction(clsName:String, funcName:String, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		var scriptClass:FlxScriptClass = classes[clsName];

		if (scriptClass != null)
		{
			if (clsName != prevClsName)
				scriptClass.reloadFields();

			prevClsName = clsName;
			return scriptClass.callFunction(funcName, funcArgs);
		}
		else
		{
			FlxG.log.warn('Cannot access class: "$clsName" as the class does not exist.');
		}
		
		return null;
	}

	/**
	 * Gets a script variable by name,
	 * preserving previous interpreter values, and restoring afterwards.
	 * 
	 * @param   clsName     The class name to get the variable
	 * @param   varName     The name of the variable you're getting
	 * @param   varStatic   (Optional) Whether or not the variable is static
	 * 
	 * @return The variable that gets returned
	 */
	public function getVariable(clsName:String, varName:String, ?varStatic:Bool = true):Dynamic
	{
		var scriptClass:FlxScriptClass = classes[clsName];

		if (scriptClass != null)
		{
			if (clsName != prevClsName)
				scriptClass.reloadFields();

			prevClsName = clsName;
			return scriptClass.getVariable(varName, varStatic);
		}
		else
		{
			FlxG.log.warn('Cannot access class: "$clsName" as the class does not exist.');
		}

		return null;
	}

	/**
	 * Sets a scruot variable by a name and value
	 * 
	 * @param   clsName     The class name to set the variable
	 * @param   varName     The name of the variable you're setting
	 * @param   varValue    The value of the variable that you're importing
	 * @param   varStatic   (Optional) Whether or not you want the variable to be static
	 */
	public function setVariable(clsName:String, varName:String, varValue:Dynamic, ?varStatic:Bool = true):Void
	{
		var scriptClass:FlxScriptClass = classes[clsName];

		if (scriptClass != null)
		{
			if (clsName != prevClsName)
				scriptClass.reloadFields();

			prevClsName = clsName;
			scriptClass.setVariable(varName, varValue, varStatic);
		}
		else
		{
			FlxG.log.warn('Cannot access class: "$clsName" as the class does not exist.');
		}
	}

	/**
	 * Registers an imported class or enum into both interpreters.
	 * 
	 * @param imprt   The import information from the parsed module
	 */
	public function addImport(imprt:FlxModuleImport):Void
	{
		if (imprt.cls != null) 
		{
			getInterp(true).variables.set(imprt.name, imprt.cls);
			getInterp(false).variables.set(imprt.name, imprt.cls);
		}

		if (imprt.enm != null)
		{
			getInterp(true).variables.set(imprt.name, imprt.enm);
			getInterp(false).variables.set(imprt.name, imprt.enm);
		}

		if (imprt.dyn != null)
		{
			getInterp(true).variables.set(imprt.name, imprt.dyn);
			getInterp(false).variables.set(imprt.name, imprt.dyn);
		}
	}

	/**
	 * Grabs the static or instance interpreter depending on context.
	 * 
	 * @param isStatic   Whether to grab the static interpreter
	 * 
	 * @return The chosen interpreter
	 */
	public function getInterp(?isStatic:Bool = false):Interp
	{
		return interp.get(Std.string(isStatic).toLowerCase());
	}

	/**
	 * Converts a FlxScriptModule to a string
	 * 
	 * @return String
	 */
	override public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("path", pkgPath.join(".")),
			LabelValuePair.weak("classes", classes),
			LabelValuePair.weak("typedefs", typedefs),
		]);
	}
}
#end
