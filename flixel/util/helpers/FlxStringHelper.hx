package flixel.util.helpers;

import haxe.Json;

using StringTools;

/**
 * Utility class for appending and merging plain text, JSON, or XML
 * string data into a single combined result. This allows multiple
 * text sources to be unified for parsing, storage, or exporting.
 * 
 * @author akaFinn
 * @since 1.6.0
 */
class FlxStringHelper
{
	/**
	 * File extension for plain text files
	 */	
	public static var TEXT_FILE_EXTS:Array<String> = ["txt"];

	/**
	 * File extension for XML files
	 */
	public static var XML_FILE_EXTS:Array<String> = ["xml"];

	/**
	 * File extension for JSON files
	 */	
	public static var JSON_FILE_EXTS:Array<String> = ["json"];

	/**
	 * Default prefix used for identifying appended text directories
	 */
    public static inline var DEFAULT_APPEND_PREFIX:String = "_append";

	/**
	 * Default prefix used for identifying merge text directories
	 */
	public static inline var DEFAULT_MERGE_PREFIX:String = "_merge";

	/**
	 * Appends plain text to the provided base string.
	 * This function performs a direct concatenation and does not
	 * attempt any parsing or structural merging.
	 *
	 * @param base The original string
	 * @param text The text to append
     * 
	 * @return The combined string
	 */
    public static function appendPlainText(base:String, text:String):String
    {
        return base + text;
    }
    
	/**
	 * Appends JSON text into a base JSON string. Behavior:
	 *  - Arrays are concatenated
	 *  - Strings are concatenated
	 *  - Nested objects are appended field-by-field
	 *  - Primitive or unmatched fields in the addition overwrite base
	 *
	 * The function returns the stringified appended JSON on success,
	 * or the original base string if parsing/append fails.
	 *
	 * @param base The original JSON string
	 * @param text The JSON string to append into base
     * 
	 * @return The appended JSON as a string, or base on error
	 */
    public static function appendJsonText(base:String, text:String):String
    {
        try {
            var baseDyn:Dynamic = FlxStringHelper.parseJsonString(base);
            var addDyn:Dynamic = FlxStringHelper.parseJsonString(text);

            if (baseDyn == null) return text;
            if (addDyn == null) return base;

            for (field in Reflect.fields(addDyn)) {
                var aVal = Reflect.field(addDyn, field);

                if (Reflect.hasField(baseDyn, field)) {
                    var bVal = Reflect.field(baseDyn, field);

                    if (Std.isOfType(bVal, Array) && Std.isOfType(aVal, Array)) {
                        Reflect.setField(
                            baseDyn,
                            field,
                            (cast(bVal, Array<Dynamic>)).concat(cast(aVal, Array<Dynamic>))
                        );
                    }
                    else if (Std.isOfType(bVal, String) && Std.isOfType(aVal, String)) {
                        Reflect.setField(baseDyn, field, (cast bVal:String) + (cast aVal:String));
                    }
                    else if (!Std.isOfType(bVal, Array) && !Std.isOfType(aVal, Array) && Reflect.fields(aVal).length > 0) {
                        for (subField in Reflect.fields(aVal)) {
                            Reflect.setField(bVal, subField, Reflect.field(aVal, subField));
                        }
                        Reflect.setField(baseDyn, field, bVal);
                    }
                    else {
                        Reflect.setField(baseDyn, field, aVal);
                    }
                } else {
                    Reflect.setField(baseDyn, field, aVal);
                }
            }

            return Json.stringify(baseDyn);
        } catch (e:Dynamic) {
            return base;
        }
    }

	/**
	 * Appends XML text into a base XML string. Behavior:
	 *  - Recursively appends nodes by tag name
	 *  - If a target node exists and contains only PCData, append its text
	 *  - If nodes do not exist in the base, clone and add them
	 *  - Preserves structure of base while adding/merging children from addition
	 *
	 * The function returns the appended XML as a string, or the original base
	 * string if parsing/append fails.
	 *
	 * @param base The original XML string
	 * @param text The XML string to append into base
     * 
	 * @return The appended XML as a string, or base on error
	 */
	public static function appendXmlText(base:String, text:String):String
	{
	    try {
	        var baseXml:Xml = Xml.parse(base);
	        var addXml:Xml  = Xml.parse(text);

	        function clone(x:Xml):Xml {
	            switch (x.nodeType) {
	                case Element:
	                    var e = Xml.createElement(x.nodeName);
	                    for (sub in x.elements()) e.addChild(clone(sub));
	                    return e;
	                case PCData:
	                    return Xml.createPCData(x.nodeValue);
	                case CData:
	                    return Xml.createCData(x.nodeValue);
	                case Comment:
	                    return Xml.createComment(x.nodeValue);
	                case DocType:
	                    return Xml.createDocType(x.nodeValue);
	                case ProcessingInstruction:
	                    return Xml.createProcessingInstruction(x.nodeName);
	                case Document:
	                    var d = Xml.createDocument();
	                    for (sub in x.elements()) d.addChild(clone(sub));
	                    return d;
	            }
	            return x;
	        }

	        function appendXml(base:Xml, addition:Xml):Void {
	            for (child in addition.elements()) {
	                var tag = child.nodeName;
	                var baseChild:Xml = null;
	                for (b in base.elements()) if (b.nodeName == tag) { baseChild = b; break; }

	                if (baseChild != null) {
	                    var childHasElements = false;
	                    for (_ in child.elements()) { childHasElements = true; break; }

	                    var firstChild = child.firstChild();
	                    var baseFirstChild = baseChild.firstChild();

	                    if (!childHasElements && firstChild != null && firstChild.nodeType == Xml.PCData) {
	                        var childText = firstChild.nodeValue;
	                        if (baseFirstChild != null && baseFirstChild.nodeType == Xml.PCData) {
	                            baseFirstChild.nodeValue += childText;
	                        } else {
	                            baseChild.addChild(Xml.createPCData(childText));
	                        }
	                    } else {
	                        appendXml(baseChild, child);
	                    }
	                } else {
	                    base.addChild(clone(child));
	                }
	            }
	        }

	        appendXml(baseXml, addXml);
	        return baseXml.toString();
	    } catch (e:Dynamic) {
	        return base;
	    }
	}

	/**
	 * Produces a simple line-by-line diff between two strings.
	 * Lines starting with:
	 *  - "-" are present in the old string but not the new
	 *  - "+" are present in the new string but not the old
	 *  - " " are unchanged
	 *
	 * This can be used to compare text content, JSON, XML, or other
	 * line-based files to identify additions and deletions.
	 *
	 * @param oldStr The original string
	 * @param newStr The updated string
	 * @return A string representing the line-by-line diff
	 */
	public static function diffStrings(oldStr:String, newStr:String):String
	{
		var oldLines = oldStr.split("\n");
		var newLines = newStr.split("\n");
		var diff:Array<String> = [];

		var i = 0;
		var j = 0;

		while (i < oldLines.length || j < newLines.length) {
			if (i >= oldLines.length) {
				diff.push("[+] " + newLines[j]);
				j++;
			} else if (j >= newLines.length) {
				diff.push("[-] " + oldLines[i]);
				i++;
			} else if (oldLines[i] == newLines[j]) {
				diff.push("    " + oldLines[i]);
				i++;
				j++;
			} else {
				var found = false;
				for (k in j...newLines.length) {
					if (oldLines[i] == newLines[k]) {
						for (l in j...k) diff.push("+ " + newLines[l]);
						j = k;
						found = true;
						break;
					}
				}

				if (!found) {
					diff.push("[-] " + oldLines[i]);
					i++;
				}
			}
		}

		return diff.join("\n");
	}

	/**
	 * Parses a JSON-formatted string and returns the corresponding Dynamic object
	 * 
	 * @param text The string you want to be parsed
	 * @return A parsed dynamic instance
	 */
	public static function parseJsonString(text:String):Dynamic
	{
		return Json.parse(~/(\r|\n|\t)/g.replace(text, ""));
	}

	/**
	 * Merges plain text to the provided base string.
	 * @param base             The original string
	 * @param text             The text to merge
	 * @param forcedOpperation (Optional) Forces a specific merge operation
	 *
	 * @return Returns a merged plain text string result.
	 */
	public static function mergePlainText(base:String, text:String, ?forcedOperation:FlxMergeOperation):String 
	{
		return base;
	}

	/**
	 * Merges JSON text into a base JSON string.
	 * @param base             The original JSON string
	 * @param text             The JSON text to merge
	 * @param forcedOpperation (Optional) Forces a specific merge operation
	 * 
	 * @return Returns the merged JSON text result as a string.
	 */
	public static function mergeJsonText(base:String, text:String, ?forcedOperation:FlxMergeOperation):String 
	{
		var parsedBase:Dynamic = FlxStringHelper.parseJsonString(base);
		var mergeContent:Array<FlxMergeDefinition> = FlxStringHelper.parseJsonString(text);

		function resolveParent(obj:Dynamic, path:String):{ parent:Dynamic, key:String } 
		{
			var parts = path.split("/");
			parts.shift();
			var current:Dynamic = obj;
			for (i in 0...parts.length - 1)
			{
				var key = parts[i];
				if (Std.isOfType(current, Array))
					current = current[Std.parseInt(key)];
				else
					current = Reflect.field(current, key);
				if (current == null) return null;
			}
			return { parent: current, key: parts[parts.length - 1] };
		}

		function getValue(obj:Dynamic, path:String):Dynamic 
		{
			var parts = path.split("/");
			parts.shift();
			var current:Dynamic = obj;
			for (key in parts)
			{
				if (Std.isOfType(current, Array))
					current = current[Std.parseInt(key)];
				else
					current = Reflect.field(current, key);
				if (current == null) return null;
			}
			return current;
		}

		function deepEquals(a:Dynamic, b:Dynamic):Bool 
		{
			if (a == b) return true;
			if (a == null || b == null) return false;
			if (Std.isOfType(a, Array) && Std.isOfType(b, Array))
			{
				if (a.length != b.length) return false;
				for (i in 0...a.length)
					if (!deepEquals(a[i], b[i])) return false;
				return true;
			}
			if (Reflect.isObject(a) && Reflect.isObject(b))
			{
				var keysA = Reflect.fields(a);
				var keysB = Reflect.fields(b);
				if (keysA.length != keysB.length) return false;
				for (k in keysA)
					if (!deepEquals(Reflect.field(a, k), Reflect.field(b, k))) return false;
				return true;
			}
			return false;
		}

		for (op in mergeContent)
		{
			switch (op.op.toLowerCase())
			{
				case "add":
					var target = resolveParent(parsedBase, op.path);
					if (target == null) continue;
					if (Std.isOfType(target.parent, Array))
					{
						var arr:Array<Dynamic> = target.parent;
						if (op.path.endsWith("/-"))
							arr.push(op.value);
						else
						{
							var index = Std.parseInt(target.key);
							if (index >= 0 && index <= arr.length)
								arr.insert(index, op.value);
						}
					}
					else Reflect.setField(target.parent, target.key, op.value);

				case "remove":
					var target = resolveParent(parsedBase, op.path);
					if (target == null) continue;
					if (Std.isOfType(target.parent, Array))
					{
						var arr:Array<Dynamic> = target.parent;
						var index = Std.parseInt(target.key);
						if (index >= 0 && index < arr.length)
							arr.remove(arr[index]);
					}
					else Reflect.deleteField(target.parent, target.key);

				case "replace":
					var target = resolveParent(parsedBase, op.path);
					if (target != null)
						Reflect.setField(target.parent, target.key, op.value);

				case "move":
					if (op.from == null) continue;
					var fromVal = getValue(parsedBase, op.from);
					var fromParent = resolveParent(parsedBase, op.from);
					var toParent = resolveParent(parsedBase, op.path);
					if (fromVal == null || fromParent == null || toParent == null) continue;
					if (Std.isOfType(fromParent.parent, Array))
					{
						var arr:Array<Dynamic> = fromParent.parent;
						arr.remove(arr[Std.parseInt(fromParent.key)]);
					}
					else Reflect.deleteField(fromParent.parent, fromParent.key);
					if (Std.isOfType(toParent.parent, Array))
					{
						var arr:Array<Dynamic> = toParent.parent;
						if (op.path.endsWith("/-"))
							arr.push(fromVal);
						else
						{
							var index = Std.parseInt(toParent.key);
							if (index >= 0 && index <= arr.length)
								arr.insert(index, fromVal);
						}
					}
					else Reflect.setField(toParent.parent, toParent.key, fromVal);

				case "copy":
					if (op.from == null) continue;
					var copyVal = getValue(parsedBase, op.from);
					if (copyVal == null) continue;
					var target = resolveParent(parsedBase, op.path);
					if (target == null) continue;
					if (Std.isOfType(target.parent, Array))
					{
						var arr:Array<Dynamic> = target.parent;
						if (op.path.endsWith("/-"))
							arr.push(copyVal);
						else
						{
							var index = Std.parseInt(target.key);
							if (index >= 0 && index <= arr.length)
								arr.insert(index, copyVal);
						}
					}
					else Reflect.setField(target.parent, target.key, copyVal);

				case "test":
					var targetVal = getValue(parsedBase, op.path);
					if (!deepEquals(targetVal, op.value))
						return base;

				default:
			}
		}

		return Json.stringify(parsedBase, "\t");
	}

	/**
	 * Merges XML text into a base XML string.
	 * @param base             The original XML string
	 * @param text             The XML text to merge
	 * @param forcedOpperation (Optional) Forces a specific merge operation
	 *
	 * @return Returns the resulting merged XML string.
	 */
	public static function mergeXmlText(base:String, text:String, ?forcedOperation:FlxMergeOperation):String 
	{
		return base;
	}
}

/**
 * Defines a single merge instruction used during data merging.
 */
typedef FlxMergeDefinition = 
{
	/** Type of merge operation (e.g., add, remove, replace). */
	var op:String;

	/** Target path within the data structure to apply the operation. */
	var path:String;

	/** Optional source path (used by move and copy). */
	@:optional var from:String;

	/** Value to be merged or used by the operation. */
	@:optional var value:Dynamic;
}

/**
 * Represents the different types of merge operations that can be applied
 * when combining two data sets or files (text, JSON, XML, etc.).
 *
 * Each operation defines how new or existing content should be handled during
 * a merge process — whether it's added, replaced, removed, or otherwise manipulated.
 */
enum abstract FlxMergeOperation(String)
{
	/**
	 * Adds new data or elements from the incoming source into the base structure.
	 * This operation is used when you want to append new content without removing or overwriting existing data.
	 */
	var ADD = "add";

	/**
	 * Removes existing data or elements from the base structure.
	 * Typically used when the merge explicitly indicates something should be deleted or excluded.
	 */
	var REMOVE = "remove";

	/**
	 * Replaces existing data in the base with data from the incoming source.
	 * This is used when old content should be fully overwritten with new values.
	 */
	var REPLACE = "replace";

	/**
	 * Moves data or elements from one location to another within the structure.
	 * Useful for reordering or reorganizing nodes or entries without creating duplicates.
	 */
	var MOVE = "move";

	/**
	 * Copies data or elements to a new location without deleting the original.
	 * Similar to MOVE, but preserves the source data while duplicating it elsewhere.
	 */
	var COPY = "copy";

	/**
	 * Performs a test or validation step without applying permanent changes.
	 * Often used to check merge feasibility, detect conflicts, or simulate the result
	 * of a merge operation before committing to it.
	 */
	var TEST = "test";
}