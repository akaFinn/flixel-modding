package flixel.system.hscript;

#if hscript
import hscript.Printer;
import hscript.Expr.TypeDecl;
import hscript.Expr.CType;

@:access(flixel.util.FlxScriptUtil)
class FlxScriptTypedef extends FlxBasic 
{
    /**
	 * The parsed class declaration representing this scripted class.
	 * Contains the original AST data extracted from the script module.
	 */
    public var decl:TypeDecl;

	/**
	 * The module that owns this class and manages interpreters,
	 * imports, and shared runtime structures.
	 */
    var module:FlxScriptModule;

    var fields:Map<String, CType>;

    /**
	 * Constructs a new script runtime typedef using its source declaration.
	 * Registers instance field maps, imports, and reloads all fields.
	 */
    public function new(decl:TypeDecl, module:FlxScriptModule)
    {
        this.decl = decl;

        this.module = module;
        this.fields = [];

        super();

        switch (decl.t)
        {
            case CTAnon(fields):
                for (field in fields)
                {
                    this.fields.set(field.name, field.t);
                }

            default:
                // TODO: Add more support..? 
        }
    }

    /**
	 * Converts a FlxScriptTypedef to a string.
	 * 
	 * @return String.
	 */
    override public function toString():String
    {
        var strFields:Map<String, String> = [];

        for (fieldKey in fields.keys())
        {
            strFields.set(fieldKey, new Printer().typeToString(fields.get(fieldKey)));
        }

        return strFields.toString();
    }
}
#end