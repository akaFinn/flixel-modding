package flixel.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;
import haxe.macro.Expr;
#end

/**
 * @author akaFinn
 * @since 1.6.0
 */
class FlxModMacro
{
    /**
     * Default macro prefix for metadata
     */
    public static inline var DEFAULT_META_MACRO_PREFIX:String = "metaPrefix";

    /**
     * Default macro prefix for icons
     */
    public static inline var DEFAULT_ICON_MACRO_PREFIX:String = "iconPrefix";

    /**
     * Main build macro entry point.
     * 
     * This scans the current class for the `@:buildModpack` metadata.
     * If found, it extracts its two string parameters (metaPath and iconPath),
     * then forwards them to `buildModpack` to inject the corresponding
     * static properties into the class.
     * 
     * @return   The list of fields for the class, possibly extended with
     *           `metaPath` & `iconPath`, if the metadata was present.
     */
    public static macro function buildModpack():Array<Field>
    {
        #if macro
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();

        for (meta in cls.meta.get()) 
        {
            if (meta.name == ":buildModpack") 
            {
                if (meta.params.length >= 2) 
                {
                    var metaPrefixExpr = meta.params[0];
                    var iconPrefixExpr = meta.params[1];

                    fields.push(
                    {
                        name: FlxModMacro.DEFAULT_META_MACRO_PREFIX,
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, metaPrefixExpr),
                        pos: Context.currentPos()
                    });

                    fields.push(
                    {
                        name: FlxModMacro.DEFAULT_ICON_MACRO_PREFIX,
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, iconPrefixExpr),
                        pos: Context.currentPos()
                    });
                } 
                else 
                {
                    Context.error("@:buildModpack requires atleast 2 arguments (metaPath, iconPath)", cls.pos);
                }
            }
        }

        return fields;
        #else
        return [];
        #end
    }
}