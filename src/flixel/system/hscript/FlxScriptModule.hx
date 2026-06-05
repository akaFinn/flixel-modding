package flixel.system.hscript;

import haxe.io.Path;
import flixel.util.FlxScriptUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

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

    var decls:Array<ModuleDecl>;

    public function new(path:String)
    {
        classes = [];
        enums = [];
        interfaces = [];
        typedefs = [];

        origin = path;
        parser = new Parser();
		interp = new Interp();

        decls = parser.parseModule(FlxFileSystem.getFileContent(path), path);
        
		for (moduleDecl in decls)
		{
			switch (moduleDecl)
			{
				case DPackage(pkg): 
                    var fileName:String = Path.withoutDirectory(path);
                    pkg.push(Path.withoutExtension(fileName));
                    this.pkg = pkg;

				case DImport(pkg, _, name):
                    var pkgName:String = pkg[pkg.length - 1];

                    if (name == null)
                        name = pkgName;

                    importPackage(pkg, name);

				case DUsing(pkg): 

				case DClass(classDecl):
					var scriptClass:FlxScriptClass = new FlxScriptClass(this, classDecl);
					this.classes.set(classDecl.name, scriptClass);

				case DEnum(enumDecl):
					var scriptEnum:FlxScriptEnum = new FlxScriptEnum(this, enumDecl);
                    this.enums.set(enumDecl.name, scriptEnum);

				case DInterface(interfaceDecl):
					var scriptInterface:FlxScriptInterface = new FlxScriptInterface(this, interfaceDecl);
                    this.interfaces.set(interfaceDecl.name, scriptInterface);

                case DTypedef(typedefDecl):
                    var scriptTypedef:FlxScriptTypedef = new FlxScriptTypedef(this, typedefDecl);
                    this.typedefs.set(typedefDecl.name, scriptTypedef);
			}
		}
    }

    public function destroy():Void
    {
        // WIP
    }

    private function importPackage(pkg:Array<String>, name:String):Void
    {
        var pkgPath:String = pkg.join('.');

        @:privateAccess
        if (FlxScriptUtil.isPackagePathScripted(pkg))
        {
            if (FlxScriptUtil.hasScriptClass(name))
            {
                var scriptClass:FlxScriptClass = FlxScriptUtil.getScriptClass(name);
                var scriptClassObj:Dynamic = {};

                for (fieldKey in scriptClass.staticFields.keys())
                {
                    Reflect.setField(scriptClassObj, fieldKey, scriptClass.staticFields.get(fieldKey));
                }

                if (!scriptClass.fieldDecls.exists('toString'))
                    Reflect.setField(scriptClassObj, 'toString', scriptClass.toString);

                if (scriptClass.fieldDecls.exists('new'))
                    Reflect.setField(scriptClassObj, 'new', scriptClass.s_new);

                interp.forceVar(name, scriptClassObj, true);
            }
        }
        else
        {
            if (Type.resolveClass(pkgPath) != null)
                interp.forceVar(name, Type.resolveClass(pkgPath), true);

            if (Type.resolveEnum(pkgPath) != null)
                interp.forceVar(name, Type.resolveEnum(pkgPath), true);
        }
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