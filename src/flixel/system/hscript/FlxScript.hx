package flixel.system.hscript;

import flixel.util.FlxDestroyUtil;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

class FlxScript implements IFlxDestroyable
{
    var expr:Expr;

    var interp:Interp;

    var parser:Parser;

    var origin:String;

    public function new(path:String)
    {
        origin = path;
        parser = new Parser();
        interp = new Interp();

        expr = parser.parseString(FlxFileSystem.getFileContent(path), path);
    }

    public function execute():Void
    {
        interp.execute(expr);
    }

    public function destroy():Void
    {
        expr = null;
        interp = null;
    }
}