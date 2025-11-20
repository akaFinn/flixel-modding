package flixel.system.hscript;

#if hscript
import flixel.system.hscript.FlxScriptModule.FlxInstanceData;
import flixel.util.FlxScriptUtil.FlxModuleImport;
import flixel.util.FlxScriptUtil.FlxClassDecl;
import hscript.Expr.FieldAccess;
import hscript.Interp;
import hscript.Expr.VarDecl;
import hscript.Expr.FunctionDecl;
import hscript.Expr.FieldDecl;

@:access(flixel.util.FlxScriptUtil)
@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptClass extends FlxBasic
{
	/**
	 * The parsed class declaration representing this scripted class.
	 * Contains the original AST data extracted from the script module.
	 */
    public var cls:FlxClassDecl;

	/**
	 * The module that owns this class and manages interpreters,
	 * imports, and shared runtime structures.
	 */
    var module:FlxScriptModule;

	/**
	 * Runtime instance data storing all field declarations (vars/functions)
	 * separated into static and default sets for accurate resolution.
	 */
    var instance:FlxInstanceData;
    
	/**
	 * Constructs a new script runtime class using its source declaration.
	 * Registers instance field maps, imports, and reloads all fields.
	 */
    public function new(cls:FlxClassDecl, module:FlxScriptModule)
    {
        this.cls = cls;
        this.module = module;

        super();

        instance = {
            fieldDecls: new Map<String, FieldDecl>(), 
            
            default_functionDecls: new Map<String, FunctionDecl>(),
            default_varDecls: new Map<String, VarDecl>(), 
            
            static_functionDecls: new Map<String, FunctionDecl>(), 
            static_varDecls: new Map<String, VarDecl>(),
        }

        for (imprt in cls.imports)
        {
            module.addImport(imprt);
        }

        reloadFields();
    }

	/**
	 * Calls a script function by name, injecting arguments,
	 * preserving previous interpreter values, and restoring afterwards.
	 * 
	 * @param funcName   The function to execute
	 * @param funcArgs   Arguments passed (optional)
	 * 
	 * @return The evaluated return value or null if unavailable
	 */
    public function callFunction(funcName:String, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		var fieldDecl:FieldDecl = instance.fieldDecls.get(funcName);
		var functionReturn:Dynamic = null;

		if (fieldDecl != null)
		{
			var curInterp:Interp = module.fieldToInterp(fieldDecl);
			var functionDecl:FunctionDecl = FlxScriptModule.getFunctionDecl(instance, fieldDecl);

			var previousValues:Map<String, Dynamic> = [];

			if (functionDecl != null)
			{
				var index:Int = 0;
				for (argument in functionDecl.args)
				{
					var value:Dynamic = null;

					if (funcArgs != null && index < funcArgs.length)
					{
						value = funcArgs[index];
					}
					else if (argument.value != null)
					{
						value = curInterp.expr(argument.value);
					}

					if (curInterp.variables.exists(argument.name))
					{
						previousValues.set(argument.name, curInterp.variables.get(argument.name));
					}

					curInterp.variables.set(argument.name, value);
					index++;
				}

				functionReturn = curInterp.execute(functionDecl.expr);
			}
			else
			{
				FlxG.log.warn('Failed to locate the function decl and therefore cannot call function.');
			}
		}
		else
		{
			FlxG.log.warn('Cannot call function: "$funcName" as the function does not exist.');
		}

		return functionReturn;
	}

	/**
	 * Rebuilds all variable/function bindings for the class.
	 * Creates actual callable closures for functions and evaluates
	 * variable expressions, populating both static and instance interpreters.
	 */
    public function reloadFields():Void
    {
        var staticInterp:Interp = module.getInterp(true);
        var defaultInterp:Interp = module.getInterp(false);

        var staticClass:Dynamic = {};

        for (fieldDecl in cls.fields)
        {
            instance.fieldDecls.set(fieldDecl.name, fieldDecl);

            switch (fieldDecl.kind)
            {
                case KFunction(f):
                    var self:FlxScriptClass = this;

                    var argNames:Array<String> = [];
                    for (arg in f.args)
                        argNames.push(arg.name);

                    var value:Dynamic = Reflect.makeVarArgs(function(args:Array<Dynamic>) 
                    {
                        var finalArgs:Array<Dynamic> = [];

                        for (i in 0...argNames.length) 
                        {
                            finalArgs.push(if (i < args.length) args[i] else null);
                        }

                        return self.callFunction(fieldDecl.name, finalArgs);
                    });

                    if (fieldDecl.access.contains(FieldAccess.AStatic))
                    {
                        instance.static_functionDecls.set(fieldDecl.name, f);
                        staticInterp.variables.set(fieldDecl.name, value);
                        Reflect.setField(staticClass, fieldDecl.name, value);
                    }
                    else 
                    {
                        instance.default_functionDecls.set(fieldDecl.name, f);
                        defaultInterp.variables.set(fieldDecl.name, value);
                    }

                case KVar(v):
                    if (fieldDecl.access.contains(FieldAccess.AStatic))
                    {
                        var value:Dynamic = staticInterp.expr(v.expr);

                        instance.static_varDecls.set(fieldDecl.name, v);
                        staticInterp.variables.set(fieldDecl.name, value);
                        Reflect.setField(staticClass, fieldDecl.name, value);
                    }
                    else
                    {
                        var value:Dynamic = defaultInterp.expr(v.expr);

                        instance.default_varDecls.set(fieldDecl.name, v);
                        defaultInterp.variables.set(fieldDecl.name, value);
                    }
            }
        }

        staticInterp.variables.set(cls.name, staticClass);
		defaultInterp.variables.set(cls.name, staticClass);
    }
}
#end
