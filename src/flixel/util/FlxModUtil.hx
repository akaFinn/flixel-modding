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
     * Default macro prefix for metadata
     */
    public static inline var DEFAULT_META_MACRO_PREFIX:String = "metaPrefix";

    /**
     * Default macro prefix for icons
     */
    public static inline var DEFAULT_ICON_MACRO_PREFIX:String = "iconPrefix";

    /**
     * Default macro prefix for configs
     */
    public static inline var DEFAULT_CONFIG_MACRO_PREFIX:String = "configPrefix";

    /**
     * Main build macro entry point.
     * 
     * This scans the current class for the `@:buildMetadata` metadata.
     * If found, it extracts its two string parameters (metaPath and iconPath),
     * then forwards them to `buildMetadata` to inject the corresponding
     * static properties into the class.
     * 
     * @return   The list of fields for the class, possibly extended with
     *           `metaPath`, `iconPath`, & `configPath` if the metadata was present.
     */
    public static macro function buildMetadata():Array<Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();

        for (meta in cls.meta.get()) 
        {
            if (meta.name == ":buildMetadata") 
            {
                if (meta.params.length >= 2) 
                {
                    var metaPathExpr = meta.params[0];
                    var iconPathExpr = meta.params[1];

                    fields.push(
                    {
                        name: FlxModUtil.DEFAULT_META_MACRO_PREFIX,
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, metaPathExpr),
                        pos: Context.currentPos()
                    });

                    fields.push(
                    {
                        name: FlxModUtil.DEFAULT_ICON_MACRO_PREFIX,
                        doc: null,
                        meta: [],
                        access: [Access.APublic, Access.AStatic],
                        kind: FieldType.FProp("default", "null", macro:String, iconPathExpr),
                        pos: Context.currentPos()
                    });

                    if (meta.params.length == 3)
                    {
                        var configPathExpr = meta.params[2];

                        fields.push(
                        {
                            name: FlxModUtil.DEFAULT_CONFIG_MACRO_PREFIX,
                            doc: null,
                            meta: [],
                            access: [Access.APublic, Access.AStatic],
                            kind: FieldType.FProp("default", "null", macro:String, configPathExpr),
                            pos: Context.currentPos()
                        });
                    }

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
                    Context.error("@:buildMetadata requires atleast 2 arguments (metaPath, iconPath)", cls.pos);
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
}