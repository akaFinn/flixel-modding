package flixel.util.helpers;

import haxe.Json;

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
	 * Default prefix used for identifying appended text directories
	 */
    public static inline var DEFAULT_APPEND_PREFIX:String = "_append";

	/**
	 * Default prefix used for identifying merge text directories
	 */
	public static inline var DEFAULT_MERGE_PREFIX:String = "_merge";

	/**
	 * File extension for plain text files
	 */	
	public static inline var PLAIN_TEXT_FILE_EXT:String = ".txt";

	/**
	 * File extension for XML files
	 */
	public static inline var XML_FILE_EXT:String = ".xml";

	/**
	 * File extension for JSON files
	 */	
	public static inline var JSON_FILE_EXT:String = ".json";

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
		return Json.parse(text);
	}
}