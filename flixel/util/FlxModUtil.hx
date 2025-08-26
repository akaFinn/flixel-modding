package flixel.util;

import haxe.macro.Context;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;

/**
 * @author akaFinn
 * @since 1.5.0
 */
class FlxModUtil
{
    /**
     * Main build macro entry point.
     * 
     * This scans the current class for the `@:buildMetadata` metadata.
     * If found, it extracts its two string parameters (metaPath and iconPath),
     * then forwards them to `buildMetadata` to inject the corresponding
     * static properties into the class.
     * 
     * @return   The list of fields for the class, possibly extended with
     *           `metaPath` and `iconPath` if the metadata was present.
     */
    public static macro function buildMetadata():Array<Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();

        for (meta in cls.meta.get()) 
        {
            if (meta.name == ":buildMetadata") 
            {
                if (meta.params.length == 2) 
                {
                    var metaPathExpr = meta.params[0];
                    var iconPathExpr = meta.params[1];

                    fields.push(
                    {
                        name: "metaPath",
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, metaPathExpr),
                        pos: Context.currentPos()
                    });

                    fields.push(
                    {
                        name: "iconPath",
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, iconPathExpr),
                        pos: Context.currentPos()
                    });

                    fields.push(
                    {
                        name: "new",
                        doc: null,
                        meta: [],
                        access: [Access.APublic],
                        kind: FieldType.FFun({
                            args: [],
                            expr: macro
                            {
                                super();
                            }
                        }),
                        pos: Context.currentPos()
                    });
                } 
                else 
                {
                    Context.error("@:buildPaths requires 2 arguments (metaPath, iconPath)", cls.pos);
                }
            }
        }

        return fields;
    }

    /**
     * Build macro function that injects a `new(file:String)` constructor
     * into the class when `@:buildModpack` metadata is found.
     * 
     * The generated constructor sets `type = FLIXEL` and calls
     * `super(file, FlxMetadataFormat)`.
     *
     * @return  The updated list of fields for the class, with a constructor added.
     */
    public static macro function buildModpack():Array<Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();

        for (meta in cls.meta.get())
        {
            if (meta.name == ":buildModpack") 
            {
                if (meta.params.length == 1) 
                {
                    var classExpr = meta.params[0];

                    fields.push(
                    {
                        name: "new",
                        doc: null,
                        meta: [],
                        access: [Access.APublic],
                        kind: FieldType.FFun({
                            args: [{ name: "file", opt: false, type: macro:String, value: null }],
                            expr: macro
                            {
                                super(file, $e{classExpr});
                            }
                        }),
                        pos: Context.currentPos()
                    });
                } 
                else 
                {
                    Context.error("@:buildModpack requires 1 argument (class)", cls.pos);
                }
            }
        }

        return fields;
    }

    #if macro
    public static function getDefinedStringRaw(value:String, defaultValue:String = ""):String
	{
        return Context.definedValue(value) ?? defaultValue;
    }

	public static function getDefinedBoolRaw(value:String, defaultValue:Bool = true):Bool
	{
		var val = getDefinedStringRaw(value);
		return val == "" ? defaultValue : (val == 'true');
	}
    #end

	public static macro function getDefinedString(val:String, defaultVal:String = ""):haxe.macro.Expr
	{
		return macro $v{getDefinedStringRaw(val, defaultVal)};
	}

	public static macro function getDefinedBool(val:String, defaultVal:Bool = true):haxe.macro.Expr
	{
		return macro $v{getDefinedBoolRaw(val, defaultVal)};
	} 
}