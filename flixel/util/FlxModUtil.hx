package flixel.util;

import haxe.macro.Context;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;

/**
 * @since 1.5.0
 */
class FlxModUtil
{
    /**
     * Build macro function that injects two static properties (`metaPath` and `iconPath`)
     * into the class where this macro is applied.
     *
     * @param   metaPath   The path to the mod's metadata file (stored as a static property).
     * @param  iconPath    The path to the mod's icon file (stored as a static property).
	 * 
     * @return             The list of fields for the class, with the new properties appended.
     */
	public static function buildModPaths(metaPath:String, iconPath:String):Array<Field>
    {
        var fields:Array<Field> = Context.getBuildFields();

        fields.push(
        {
            name: "metaPath",
			doc: null,
			meta: [],
			access: [Access.APublic, Access.AStatic],
			kind: FieldType.FProp("default", "null", macro:Dynamic, macro $v{metaPath}),
			pos: Context.currentPos()
        });

        fields.push(
        {
            name: "iconPath",
			doc: null,
			meta: [],
			access: [Access.APublic, Access.AStatic],
			kind: FieldType.FProp("default", "null", macro:Dynamic, macro $v{iconPath}),
			pos: Context.currentPos()
        });

        return fields;
    }    
}