package flixel.system.hscript;

import flixel.util.FlxScriptUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.system.hscript._internal.*;

class FlxScriptModule implements IFlxDestroyable
{
    public var classes:Map<String, FlxScriptClass>;

    public var enums:Map<String, FlxScriptEnum>;

    public var interfaces:Map<String, FlxScriptInterface>;

    public var typedefs:Map<String, FlxScriptTypedef>;

    var pkg:Array<String>;

    var parser:Parser;

    var interp:Interp;

    var origin:String;

    public function new(path:String)
    {
        classes = [];
        enums = [];
        interfaces = [];
        typedefs = [];

        origin = path;
        parser = new Parser();
		interp = new Interp();

		for (moduleDecl in parser.parseModule(FlxFileSystem.getFileContent(path), path))
		{
			switch (moduleDecl)
			{
				case DPackage(pkg): 
                    this.pkg = pkg;

				case DImport(pkg, _, name):
                    var pkgPath:String = pkg.join(".");
                    var pkgName:String = pkg[pkg.length - 1];

                    if (name == null)
                        name = pkgName;

                    if (FlxScriptUtil.hasScriptClass(pkgName))
                    {
                        interp.variables.set(name, FlxScriptUtil.getScriptClass(pkgName));
                    }
                    else
                    {
                        if (Type.resolveClass(pkgPath) != null)
                            importClass(Type.resolveClass(pkgPath), name);

                        if (Type.resolveEnum(pkgPath) != null)
                            importEnum(Type.resolveEnum(pkgPath), name);
                    }

				case DUsing(pkg): 

				case DClass(classDecl):
					var scriptClass:FlxScriptClass = new FlxScriptClass(this, classDecl);
					this.classes.set(classDecl.name, scriptClass);

				case DTypedef(typedefDecl):
					trace('Typedef: ${typedefDecl}');

				case DEnum(enumDecl):
					trace('Enum: ${enumDecl}');

				case DInterface(interfaceDecl):
					trace('Interface: ${interfaceDecl}');
			}
		}
    }

    public function destroy():Void
    {
        // WIP
    }

    private function importClass(cls:Class<Dynamic>, name:String):Void
    {
        interp.variables.set(name, cls);
    }

    private function importEnum(enm:Enum<Dynamic>, name:String):Void
    {
        interp.variables.set(name, enm);
    }

    function toString():String
    {
        return FlxStringUtil.getDebugString([
            LabelValuePair.weak('path', origin),
            LabelValuePair.weak('classes', classes),
            LabelValuePair.weak('enums', enums),
            LabelValuePair.weak('interfaces', interfaces),
            LabelValuePair.weak('typedefs', typedefs),
        ]);
    }
}