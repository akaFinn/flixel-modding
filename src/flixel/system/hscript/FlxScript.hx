package flixel.system.hscript;

import flixel.util.FlxScriptUtil;
import flixel.util.FlxScriptUtil.FlxModuleImport;
import hscript.Interp;
import hscript.Expr;

// Unfinished Class hehe haha
@:access(flixel.util.FlxScriptUtil)
class FlxScript extends FlxBasic
{   
    public var expr:Expr;

    private var interp:Interp;

    var imports:Array<FlxModuleImport>;

    public function new(expr:Expr, imports:Array<FlxModuleImport>)
    {
        this.expr = expr;

        this.interp = FlxScriptUtil.buildInterp();
        this.imports = imports;

        super();

        for (imprt in imports)
        {
            addImport(imprt);
        }
    }

    public function execute():Void
    {
        interp.execute(expr);    
    }

    public function addImport(imprt:FlxModuleImport):Void
	{
		if (imprt.cls != null) 
			interp.variables.set(imprt.name, imprt.cls);

		if (imprt.enm != null)
			interp.variables.set(imprt.name, imprt.enm);
	}
}