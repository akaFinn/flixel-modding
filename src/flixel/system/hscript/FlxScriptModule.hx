package flixel.system.hscript;

#if hscript
import flixel.util.FlxScriptUtil;
import hscript.Interp;
import hscript.Expr;
import hscript.Expr.VarDecl;
import hscript.Expr.FunctionDecl;
import hscript.Expr.FieldDecl;
import flixel.util.FlxScriptUtil.FlxClassDecl;
import flixel.util.FlxScriptUtil.FlxTypeDecl;

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
	 * Every scripted class parsed from the module.
	 * The key is the class name, and the value is its runtime wrapper.
	 */
	public var classes:Map<String, FlxScriptClass>;

	/**
	 * Every typedef parsed from the module.
	 * Stored as runtime-friendly wrappers for lookup and execution.
	 */
	public var typedefs:Map<String, FlxScriptTypeDef>;

	/**
	 * A map containing two interpreters:
	 * one used for static access and one used for instance access.
	 * Keys are `true` and `false` (as strings).
	 */
    private var interp:Map<String, Interp>;

	/**
	 * Constructs a new script module from parsed class & typedef declarations.
	 * 
	 * @param classDecls   All parsed class declarations
	 * @param typeDecls    All parsed typedef declarations
	 * @param pkg          (Optional) The module's package path
	 */
    public function new(classDecls:Map<String, FlxClassDecl>, typeDecls:Map<String, FlxTypeDecl>, ?pkg:Array<String> = null)
    {
		interp = new Map<String, Interp>();
		interp.set("true", FlxScriptUtil.buildInterp());
		interp.set("false", FlxScriptUtil.buildInterp());

		pkgPath = pkg;
		classes = new Map<String, FlxScriptClass>();
		typedefs = new Map<String, FlxScriptTypeDef>();

        super();

		for (classDecl in classDecls)
		{
			var scriptClass = new FlxScriptClass(classDecl, this);
			classes.set(classDecl.name, scriptClass);
		}
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
	 * Gets the correct function declaration (static or instance)
	 * from the given instance data and field declaration.
	 */
	public static function getFunctionDecl(instance:FlxInstanceData, fieldDecl:FieldDecl):FunctionDecl
	{
		return if (fieldDecl.access.contains(FieldAccess.AStatic)) instance.static_functionDecls[fieldDecl.name] else instance.default_functionDecls[fieldDecl.name];
	}

	/**
	 * Gets the correct variable declaration (static or instance)
	 * from the given instance data and field declaration.
	 */
	public static function getVarDecl(instance:FlxInstanceData, fieldDecl:FieldDecl):VarDecl
	{
		return if (fieldDecl.access.contains(FieldAccess.AStatic)) instance.static_varDecls[fieldDecl.name] else instance.default_varDecls[fieldDecl.name];
	}

	/**
	 * Determines which interpreter a field should use based on access.
	 * Static fields use the static interpreter, everything else
	 * falls back to the instance interpreter.
	 */
	private function fieldToInterp(fieldDecl:FieldDecl):Interp
	{
		if (fieldDecl.access.contains(FieldAccess.AStatic) || fieldDecl == null)
		{
			return getInterp(true);
		}
		else 
		{
			return getInterp(false);
		}
	}
}

/**
 * Holds all relevant information for a script class instance.
 * Includes separated maps for static and instance function/var declarations,
 * allowing for clean resolution at runtime.
 */
typedef FlxInstanceData = 
{
	var fieldDecls:Map<String, FieldDecl>;
	
    var default_functionDecls:Map<String, FunctionDecl>;
	var default_varDecls:Map<String, VarDecl>;

	var static_functionDecls:Map<String, FunctionDecl>;
	var static_varDecls:Map<String, VarDecl>;
}
#end
