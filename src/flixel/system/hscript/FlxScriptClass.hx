package flixel.system.hscript;

#if hscript
import hscript.Printer;
import hscript.Expr.FieldAccess;
import hscript.Interp;
import hscript.Expr.VarDecl;
import hscript.Expr.FunctionDecl;
import hscript.Expr.FieldDecl;
import hscript.Expr.ClassDecl;
import flixel.util.FlxScriptUtil.FlxModuleImport;

@:access(flixel.util.FlxScriptUtil)
@:access(flixel.system.hscript.FlxScriptModule)
class FlxScriptClass extends FlxBasic
{
	/**
	 * The parsed class declaration representing this scripted class.
	 * Contains the original AST data extracted from the script module.
	 */
    public var decl:ClassDecl;

	/**
	 * The class that is being extended
	 */
	public var superClass:Dynamic;

	/**
	 * The module that owns this class and manages interpreters,
	 * imports, and shared runtime structures.
	 */
    var module:FlxScriptModule;

	/**
	 * The fields for the class,
	 * both static and default.
	 */
	private var fieldDecls:Map<String, FieldDecl>;

	/**
	 * Built Variables.
	 */
	private var varDecls:Map<String, VarDecl>;

	/**
	 * Build Functions.
	 */
	private var functionDecls:Map<String, FunctionDecl>;
    
	/**
	 * Constructs a new script runtime class using its source declaration.
	 * Registers instance field maps, imports, and reloads all fields.
	 */
    public function new(decl:ClassDecl, module:FlxScriptModule)
    {
        this.decl = decl;
        this.module = module;

        super();

		fieldDecls = new Map<String, FieldDecl>();
		
		functionDecls = new Map<String, FunctionDecl>();
		varDecls = new Map<String, VarDecl>();

		if (decl.extend != null)
		{
			var superClassPath:Array<String> = new Printer().typeToString(decl.extend).split(".");
			var superClassName:String = superClassPath[superClassPath.length - 1];

			var superClassImport:FlxModuleImport = module.imports.get(superClassName);
			
			if (superClassImport != null)
			{
				if (superClassImport.cls != null)
				{
					superClass = superClassImport.cls;
				}
				else if (superClassImport.dyn != null)
				{
					superClass = superClassImport.dyn;
				}
				else
				{
					FlxG.log.warn('Cannot extend to class: "${superClassPath.join(".")}" this import is not a class.');
				}
			}
			else
			{
				FlxG.log.warn('Cannot extend to class: "${superClassPath.join(".")}" this class was not imported.');
			}
		}

        reloadFields();
    }

	/**
	 * Calls a script function by name, injecting arguments,
	 * preserving previous interpreter values, and restoring afterwards.
	 * 
	 * @param   funcName   The function to execute
	 * @param   funcArgs   Arguments passed (optional)
	 * 
	 * @return The evaluated return value or null if unavailable
	 */
    public function callFunction(funcName:String, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		var fieldDecl:FieldDecl = fieldDecls.get(funcName);
		var functionReturn:Dynamic = null;

		if (fieldDecl != null)
		{
			var curInterp:Interp = this.fieldToInterp(fieldDecl);
			var functionDecl:FunctionDecl = this.getFunctionDecl(fieldDecl);

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

				switch (funcName)
				{
					case "new":
						var instance:Dynamic = this.buildInstance();

						functionReturn = instance;
						module.getInterp(false).variables.set("this", instance);
					
					default: 
						functionReturn = curInterp.execute(functionDecl.expr);
				}
			}
		}
		else
		{
			if (decl.extend != null)
			{
				switch (funcName)
				{
					case "new":
						var superClassInstance = Type.createInstance(superClass, funcArgs);
						module.getInterp().variables.set("super", superClassInstance);

						functionReturn = superClassInstance;
					
					default:
						var superClassInstance = Type.createInstance(superClass, []);
						var superFunc:Dynamic = Reflect.field(superClassInstance, funcName);

						if (superFunc != null)
						{
							functionReturn = Reflect.callMethod(superClassInstance, superFunc, funcArgs);
						}
						else
						{
							FlxG.log.warn('Cannot call function: "$funcName" as the function does not exist.');
						}
				}
			}
			else
			{
				FlxG.log.warn('Cannot call function: "$funcName" as the function does not exist.');
			}
		}

		return functionReturn;
	}

	/**
	 * Gets a script variable by name,
	 * preserving previous interpreter values, and restoring afterwards.
	 * 
	 * @param   varName     The name of the variable you're getting
	 * @param   varStatic   (Optional) Whether or not the variable is static
	 * 
	 * @return The variable that gets returned
	 */
	public function getVariable(varName:String, ?varStatic:Bool = true):Dynamic
	{
		if (fieldDecls.exists(varName))
		{
			var curInterp:Interp = module.getInterp(varStatic);

			if (curInterp.variables.exists(varName)) return curInterp.variables.get(varName);
			else return convertFieldDecl(fieldDecls.get(varName));
		}
		else
		{
			FlxG.log.warn('Cannot get variable: "$varName" as the variable does not exist.');
		}

		return null;
	}

	/**
	 * Sets a scruot variable by a name and value
	 * 
	 * @param   varName     The name of the variable you're setting
	 * @param   varValue    The value of the variable that you're importing
	 * @param   varStatic   (Optional) Whether or not you want the variable to be static
	 */
	public function setVariable(varName:String, varValue:Dynamic, ?varStatic:Bool = true):Void
	{
		if (fieldDecls.exists(varName))
		{
			FlxG.log.warn('Cannot set variable: "$varName" as the variable already exists.');
		}
		else
		{
			var curInterp:Interp = module.getInterp(varStatic);
			curInterp.variables.set(varName, varValue);
		}
	}

	/**
	 * Rebuilds all variable/function bindings for the class.
     * 
	 * Creates actual callable closures for functions and evaluates
	 * variable expressions, populating both static and instance interpreters.
	 */
    public function reloadFields():Void
    {
        var staticClass:Dynamic = {};

        for (fieldDecl in decl.fields)
        {
			var value:Dynamic = null;
			var curInterp:Interp = fieldToInterp(fieldDecl);

            fieldDecls.set(fieldDecl.name, fieldDecl);

            switch (fieldDecl.kind)
            {
                case KFunction(f):
					value = convertFunctionDecl(fieldDecl, f);

					functionDecls.set(fieldDecl.name, f);
                    curInterp.variables.set(fieldDecl.name, value);

                    if (fieldDecl.access.contains(FieldAccess.AStatic))
                    	Reflect.setField(staticClass, fieldDecl.name, value);

                case KVar(v):
					if (v.expr != null) value = convertVarDecl(fieldDecl, v);

					varDecls.set(fieldDecl.name, v);
					curInterp.variables.set(fieldDecl.name, value);

                    if (fieldDecl.access.contains(FieldAccess.AStatic))
                        Reflect.setField(staticClass, fieldDecl.name, value);
            }
        }

		if (decl.extend != null)
		{
			var superClassInstance:Dynamic = Type.createInstance(superClass, []);

			for (superFieldName in Reflect.fields(superClassInstance).concat(Type.getInstanceFields(superClass)))
			{
				var superField:Dynamic = Reflect.field(superClassInstance, superFieldName);
				module.getInterp().variables.set(superFieldName, superField);
			}
		}

        for (interp in module.interp)
		{
			interp.variables.set(decl.name, staticClass);
		}
    }

	/**
	 * Builds the instance of the scripted class
	 * 
	 * @return The built instance
	 */
	private function buildInstance():Dynamic
	{
		var instance:Dynamic = {};

		var curInterp:Interp = module.getInterp();
		var functionDecl:FunctionDecl = functionDecls.get("new");

		if (functionDecl != null)
		{
			for (clsFieldDecl in fieldDecls)
			{
				var value:Dynamic = null;

				switch (clsFieldDecl.kind)
				{
					case KFunction(f): value = convertFunctionDecl(clsFieldDecl, f);
					case KVar(v): if (v.expr != null) value = convertVarDecl(clsFieldDecl, v);
				}

				Reflect.setField(instance, clsFieldDecl.name, value);
			}

			if (decl.extend != null)
			{
				var superClassInstance:Dynamic = Type.createInstance(superClass, []);

				for (superFieldName in Reflect.fields(superClassInstance).concat(Type.getInstanceFields(superClass)))
				{
					var superField:Dynamic = Reflect.field(superClassInstance, superFieldName);
					Reflect.setField(instance, superFieldName, superField);
				}

				curInterp.variables.set("super", () -> {Type.createInstance(superClass, []);});
			}

			if (!Reflect.hasField(instance, "toString"))
			{
				Reflect.setField(instance, "toString", () -> {return decl.name;});
			}
			
			curInterp.execute(functionDecl.expr);
			return instance;
		}

		FlxG.log.warn('Failed to build scripted instance due to the script missing a "new" function');
		return null;
	}

	/**
	 * Converts a `FieldDecl` to a dynamic value,
	 * designed to be used by functions that are looping in fields.
	 * 
	 * @param   fieldDecl   The field that you'll be converting.
	 * 
	 * @return  Dynamic
	 */
	public function convertFieldDecl(fieldDecl:FieldDecl):Dynamic
	{
		switch (fieldDecl.kind)
		{
			case KFunction(f): return convertFunctionDecl(fieldDecl, f);
			case KVar(v): return convertVarDecl(fieldDecl, v);
		}
	}

	/**
	 * Converts a `VarDecl` to a dynamic value, 
	 * designed to be used by the `convertFieldDecl` function.
	 * 
	 * @param   fieldDecl   The field that'll be used for other data.
	 * @param   varDecl     The variable that'll get converted.
	 * 
	 * @return  A working dynamic value.
	 */
	private function convertVarDecl(fieldDecl:FieldDecl, varDecl:VarDecl):Dynamic
	{
		return if (fieldDecl.access.contains(FieldAccess.AStatic)) module.getInterp(true).expr(varDecl.expr) else module.getInterp(false).expr(varDecl.expr);
	}

	/**
	 * Converts a `FunctionDecl` to a dynamic value, 
	 * designed to be used by the `convertFieldDecl` function.
	 * 
	 * @param   fieldDecl      The field that'll be used for other data.
	 * @param   functionDecl   The function that'll get converted.
	 * 
	 * @return  A working dynamic value.
	 */
	private function convertFunctionDecl(fieldDecl:FieldDecl, functionDecl:FunctionDecl):Dynamic
	{
		var self:FlxScriptClass = this;
		var argNames:Array<String> = [];

		for (arg in functionDecl.args)
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

		return value;
	}

	/**
	 * Gets the correct function declaration (static or default)
	 * from the given instance data and field declaration.
	 */
	private function getFunctionDecl(fieldDecl:FieldDecl):FunctionDecl
	{
		return this.functionDecls[fieldDecl.name];
	}

	/**
	 * Gets the correct variable declaration (static or default)
	 * from the given instance data and field declaration.
	 */
	private function getVarDecl(fieldDecl:FieldDecl):VarDecl
	{
		return this.varDecls[fieldDecl.name];
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
			return module.getInterp(true);
		}
		else 
		{
			return module.getInterp(false);
		}
	}

	/**
	 * Converts a FlxScriptClass to a string.
	 * 
	 * @return String.
	 */
	override public function toString():String 
	{
		if (fieldDecls.exists("toString") != true)
		{
			return this.decl.name;
		}
		else
		{
			return this.callFunction("toString", []);
		}
	}
}
#end
