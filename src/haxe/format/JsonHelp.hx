package haxe.format;

/*
 * MIT License
 * 
 * Copyright (c) 2025 Phineas Francis
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

class JsonHelp
{
    public static function getField(json:Dynamic, field:String, ?defaultValue:Dynamic = null):Dynamic
    {
        if (Reflect.hasField(json, field) && json != null)
            return Reflect.field(json, field);
        
        if (defaultValue != null)
            return defaultValue;
        return null;
    }

    public static function getFieldString(json:Dynamic, field:String, ?defaultValue:String = null):String
        return Std.string(getField(json, field, defaultValue));

    public static function getFieldInt(json:Dynamic, field:String, ?defaultValue:Int = null):Int
        return Std.int(getFieldFloat(json, field, defaultValue));

    public static function getFieldFloat(json:Dynamic, field:String, ?defaultValue:Float = null):Float
        return cast(getField(json, field, defaultValue), Float);

    public static function getFieldBool(json:Dynamic, field:String, ?defaultValue:Bool = null):Bool
        return cast(getField(json, field, defaultValue), Bool);
}