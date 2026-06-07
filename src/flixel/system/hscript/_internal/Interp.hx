package flixel.system.hscript._internal;

import haxe.PosInfos;
import haxe.Constraints.IMap;
import flixel.system.hscript._internal.*;
import flixel.system.hscript._internal.Expr;

private enum Stop {
    SBreak;
    SContinue;
    SReturn;
}

class Interp {
    public var variables:Map<String, Dynamic>;

    var varInfos:Map<String, VarInfo>;

    public static final KEYWORDS:Array<String> = ['for','if','else','switch','case','var','final','while','do','function','return','break','continue','inline','new','throw','try','catch','default','cast','in','true','false','null','this','super'];

    var locals:Map<String, {r:Dynamic, ?isfinal:Bool}>;
    var binops:Map<String, Expr->Expr->Dynamic>;

    var depth:Int;
    var inTry:Bool;
    var declared:Array<{n:String, old:{r:Dynamic, ?isfinal:Bool}}>;
    var returnValue:Dynamic;

    var curExpr:Expr;

    public function new() {
        locals = new Map();
        declared = [];
        depth = 0;
        inTry = false;
        resetVariables();
        initOps();
    }

    public function copy():Interp {
        var interp = new Interp();
        for (name in variables.keys())
        {
            if (!interp.hasVar(name))
                interp.setVar(name, variables.get(name), (varInfos.exists(name)) ? varInfo(name) : null);
        }
        return interp;
    }

    private function resetVariables() {
        varInfos = new Map();
        variables = new Map();
        variables.set("null", null);
        variables.set("true", true);
        variables.set("false", false);

        variables.set("trace", Reflect.makeVarArgs(function(el) {
            var inf = posInfos();
            var v = el.shift();
            if (el.length > 0)
                inf.customParams = el;
            haxe.Log.trace(Std.string(v), inf);
        }));

        variables.set("Std", Std);
        variables.set("Math", Math);

        variables.set("Type", Type);
        variables.set("Date", Date);
        variables.set("Reflect", Reflect);
        variables.set("StringTools", StringTools);
        variables.set("DateTools", DateTools);
        variables.set("Lambda", Lambda);

        #if sys
        variables.set("Sys", Sys);
        #end
    }

    public function posInfos():PosInfos {
        if (curExpr != null)
            return cast {fileName: curExpr.origin, lineNumber: curExpr.line};
        return cast {fileName: "hscript", lineNumber: 0};
    }

    function initOps() {
        var me = this;
        binops = new Map();
        binops.set("+", function(e1, e2) return me.expr(e1) + me.expr(e2));
        binops.set("-", function(e1, e2) return me.expr(e1) - me.expr(e2));
        binops.set("*", function(e1, e2) return me.expr(e1) * me.expr(e2));
        binops.set("/", function(e1, e2) return me.expr(e1) / me.expr(e2));
        binops.set("%", function(e1, e2) return me.expr(e1) % me.expr(e2));
        binops.set("&", function(e1, e2) return me.expr(e1) & me.expr(e2));
        binops.set("|", function(e1, e2) return me.expr(e1) | me.expr(e2));
        binops.set("^", function(e1, e2) return me.expr(e1) ^ me.expr(e2));
        binops.set("<<", function(e1, e2) return me.expr(e1) << me.expr(e2));
        binops.set(">>", function(e1, e2) return me.expr(e1) >> me.expr(e2));
        binops.set(">>>", function(e1, e2) return me.expr(e1) >>> me.expr(e2));
        binops.set("==", function(e1, e2) return me.expr(e1) == me.expr(e2));
        binops.set("!=", function(e1, e2) return me.expr(e1) != me.expr(e2));
        binops.set(">=", function(e1, e2) return me.expr(e1) >= me.expr(e2));
        binops.set("<=", function(e1, e2) return me.expr(e1) <= me.expr(e2));
        binops.set(">", function(e1, e2) return me.expr(e1) > me.expr(e2));
        binops.set("<", function(e1, e2) return me.expr(e1) < me.expr(e2));
        binops.set("||", function(e1, e2) return me.expr(e1) == true || me.expr(e2) == true);
        binops.set("&&", function(e1, e2) return me.expr(e1) == true && me.expr(e2) == true);
        binops.set("=", assign);
        binops.set("...", function(e1, e2) return new IntIterator(me.expr(e1), me.expr(e2)));
        binops.set("is", function(e1, e2) return #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (me.expr(e1), me.expr(e2)));
        binops.set("??", function(e1, e2) return me.expr(e1) ?? me.expr(e2));
        assignOp("+=", function(v1:Dynamic, v2:Dynamic) return v1 + v2);
        assignOp("-=", function(v1:Float, v2:Float) return v1 - v2);
        assignOp("*=", function(v1:Float, v2:Float) return v1 * v2);
        assignOp("/=", function(v1:Float, v2:Float) return v1 / v2);
        assignOp("%=", function(v1:Float, v2:Float) return v1 % v2);
        assignOp("&=", function(v1, v2) return v1 & v2);
        assignOp("|=", function(v1, v2) return v1 | v2);
        assignOp("^=", function(v1, v2) return v1 ^ v2);
        assignOp("<<=", function(v1, v2) return v1 << v2);
        assignOp(">>=", function(v1, v2) return v1 >> v2);
        assignOp(">>>=", function(v1, v2) return v1 >>> v2);
        assignOp("??" + "=", function(v1, v2) return v1 ?? v2);
    }

    public function varInfo(name):Null<VarInfo> {
        if (varInfos.exists(name))
            return varInfos.get(name);

        return null;
    }

    public function setVar(name:String, value:Dynamic, ?vInfo:VarInfo):Dynamic {
        if (vInfo != null) {
            variables.set(name, value);
            varInfos.set(name, vInfo);
            return value;
        }

        if (varInfos.exists(name)) {
            vInfo = varInfo(name);
            if (vInfo.isFinal || vInfo.isFunction)
                return error(EInvalidAccess(name));
    
            if (vInfo.set != null) {
                switch (vInfo.set) {
                    case PSet:
                        value = resolve('set_${name}')(value);
                    case PGet:
                        return error(EInvalidProperty("get"));
                    case PNever:
                        return error(EInvalidAccess(name));
                    case PDynamic:
                        if (hasVar('set_${name}'))
                            value = resolve('set_${name}')(value);
                    default:
                } 
            }
        }

        variables.set(name, value);
        return value;
    }

    public function hasVar(name:String):Bool {
        return variables.exists(name);
    }

    public function resolve(id:String):Dynamic {
        if (!hasVar(id)) 
            return error(EUnknownVariable(id));

        if (varInfos.exists(id)) {
            var vInfo = varInfo(id);
            if (vInfo.get != null) {
                switch (vInfo.get) {
                    case PSet:
                        return error(EInvalidProperty("set"));
                    case PGet:
                        return resolve('get_${id}')();
                    case PNever:
                        return error(EInvalidAccess(id));
                    case PDynamic:
                        if (hasVar('get_${id}'))
                            return resolve('get_${id}')();
                        return variables.get(id);
                    default:
                        return variables.get(id);
                }
            }
        }

        return variables.get(id);
    }

    function assign(e1:Expr, e2:Expr):Dynamic {
        var v = expr(e2);
        switch (Tools.expr(e1)) {
            case EIdent(id):
                var l = locals.get(id);
                if (l != null && l.isfinal && l.r != null)
                    return error(EInvalidAccess(id));
                if (l == null)
                    setVar(id, v)
                else
                    l.r = v;
            case EField(e, f):
                v = set(expr(e), f, v);
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    setMapValue(arr, index, v);
                } else {
                    arr[index] = v;
                }

            default:
                error(EInvalidOp("="));
        }
        return v;
    }

    function assignOp(op, fop:Dynamic->Dynamic->Dynamic) {
        var me = this;
        binops.set(op, function(e1, e2) return me.evalAssignOp(op, fop, e1, e2));
    }

    function evalAssignOp(op, fop, e1, e2):Dynamic {
        var v;
        switch (Tools.expr(e1)) {
            case EIdent(id):
                var l = locals.get(id);
                v = fop(expr(e1), expr(e2));
                if (l != null && l.isfinal && l.r != null)
                    return error(EInvalidAccess(id));
                if (l == null)
                    setVar(id, v)
                else
                    l.r = v;
            case EField(e, f):
                var obj = expr(e);
                v = fop(get(obj, f), expr(e2));
                v = set(obj, f, v);
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    v = fop(getMapValue(arr, index), expr(e2));
                    setMapValue(arr, index, v);
                } else {
                    v = fop(arr[index], expr(e2));
                    arr[index] = v;
                }
            default:
                return error(EInvalidOp(op));
        }
        return v;
    }

    function increment(e:Expr, prefix:Bool, delta:Int):Dynamic {
        curExpr = e;
        var e = e.e;

        switch (e) {
            case EIdent(id):
                var l = locals.get(id);
                var v:Dynamic = (l == null) ? resolve(id) : l.r;
                if (l != null && l.isfinal && l.r != null)
                    return error(EInvalidAccess(id));
                if (prefix) {
                    v += delta;
                    if (l == null)
                        setVar(id, v)
                    else
                        l.r = v;
                } else if (l == null)
                    setVar(id, v + delta)
                else
                    l.r = v + delta;
                return v;
            case EField(e, f):
                var obj = expr(e);
                var v:Dynamic = get(obj, f);
                if (prefix) {
                    v += delta;
                    set(obj, f, v);
                } else
                    set(obj, f, v + delta);
                return v;
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    var v = getMapValue(arr, index);
                    if (prefix) {
                        v += delta;
                        setMapValue(arr, index, v);
                    } else {
                        setMapValue(arr, index, v + delta);
                    }
                    return v;
                } else {
                    var v = arr[index];
                    if (prefix) {
                        v += delta;
                        arr[index] = v;
                    } else
                        arr[index] = v + delta;
                    return v;
                }
            default:
                return error(EInvalidOp((delta > 0) ? "++" : "--"));
        }
    }

    public function execute(expr:Expr):Dynamic {
        depth = 0;
        locals = new Map();
        declared = new Array();
        return exprReturn(expr);
    }

    function exprReturn(e):Dynamic {
        try {
            return expr(e);
        } catch (e:Stop) {
            switch (e) {
                case SBreak:
                    throw "Invalid break";
                case SContinue:
                    throw "Invalid continue";
                case SReturn:
                    var v = returnValue;
                    returnValue = null;
                    return v;
            }
        }
        return null;
    }

    public function field(fd:FieldDecl):{v:Dynamic, i:VarInfo} {
        var value:Dynamic = null;
        var vInfo:VarInfo = {
            name: fd.name,
            access: fd.access.copy(),
            isFinal: null,
            isFunction: null,
            get: null,
            set: null,
        }
        
        switch (fd.kind) {
            case KVar(v):
                vInfo.isFinal = v.isfinal;
                vInfo.isFunction = false;
                vInfo.get = v.get;
                vInfo.set = v.set;

                if (v.expr != null)
                    value = expr(v.expr);

            case KFunction(f):
                vInfo.isFinal = false;
                vInfo.isFunction = true;

                var minArgLength:Int = 0;
                var argNames:Array<String> = [];
                var me:Interp = this;

                for (arg in f.args) {
                    argNames.push(arg.name);
                    if (!arg.opt && arg.value == null)
                        minArgLength++;
                }

                value = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                    var funcReturn:Dynamic = null;

                    if (args.length < minArgLength)
                        return error(ECustom('Invalid number of parameters. Got ${args.length}, required ${minArgLength} for function "${fd.name}"'));

                    var argIndex:Int = 0;
                    var prevValues:Map<String, Dynamic> = [];
                    var prevVarInfos:Map<String, VarInfo> = [];

                    for (arg in f.args) {
                        var argName:String = arg.name;
                        var argValue:Dynamic = null;

                        if ((args != null || args.length != 0) && argIndex < args.length)
                            argValue = args[argIndex];
                        else if (arg.value != null)
                            argValue = me.expr(arg.value);

                        if (argValue != null || arg.opt) {
                            // trace('"${arg.name}": ${argValue}');
                            locals.set(argName, {r: argValue, isfinal: false});
                        }
                        argIndex++;
                    }

                    funcReturn = exprReturn(f.expr);
                    return funcReturn;
                });
        }

        return {v: value, i: vInfo};
    }

    function duplicate<T>(h:Map<String, T>) {
        var h2 = new Map();
        for (k in h.keys())
            h2.set(k, h.get(k));
        return h2;
    }

    function restore(old:Int) {
        while (declared.length > old) {
            var d = declared.pop();
            locals.set(d.n, d.old);
        }
    }

    inline function error(eDef:ErrorDef, rethrow = false):Dynamic {
        var e = new Error(eDef, 0, 0, 'hscript', 0);
        if (curExpr != null)
            e = new Error(eDef, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line);

        if (rethrow)
            this.rethrow(e)
        else
            throw e;
        return null;
    }

    inline function rethrow(e:Dynamic) {
        #if hl
        hl.Api.rethrow(e);
        #else
        throw e;
        #end
    }

    public function expr(e:Expr):Dynamic {
        curExpr = e;
        var e = e.e;

        switch (e) {
            case EConst(c):
                switch (c) {
                    case CInt(v): return v;
                    case CFloat(f): return f;
                    case CString(s): return s;
                }
            case EIdent(id):
                var l = locals.get(id);
                if (l != null)
                    return l.r;
                return resolve(id);
            case EVar(n, _, e):
                declared.push({n: n, old: locals.get(n)});
                locals.set(n, {r: (e == null) ? null : expr(e)});
                return null;
            case EFinal(n, _, e):
                declared.push({n: n, old: locals.get(n)});
                locals.set(n, {r: (e == null) ? null : expr(e), isfinal: true});
                return null;
            case EParent(e):
                return expr(e);
            case EBlock(exprs):
                var old = declared.length;
                var v = null;
                for (e in exprs)
                    v = expr(e);
                restore(old);
                return v;
            case EField(e, f):
                return get(expr(e), f);
            case EBinop(op, e1, e2):
                var fop = binops.get(op);
                if (fop == null)
                    error(EInvalidOp(op));
                return fop(e1, e2);
            case EUnop(op, prefix, e):
                switch (op) {
                    case "!":
                        return expr(e) != true;
                    case "-":
                        return -expr(e);
                    case "++":
                        return increment(e, prefix, 1);
                    case "--":
                        return increment(e, prefix, -1);
                    case "~":
                        return ~expr(e);
                    default:
                        error(EInvalidOp(op));
                }
            case ECall(e, params):
                var args = new Array();
                for (p in params)
                    args.push(expr(p));

                switch (Tools.expr(e)) {
                    case EField(e, f):
                        var obj = expr(e);
                        if (obj == null)
                            error(EInvalidAccess(f));
                        return fcall(obj, f, args);
                    default:
                        return call(null, expr(e), args);
                }
            case EIf(econd, e1, e2):
                return if (expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);
            case EWhile(econd, e):
                whileLoop(econd, e);
                return null;
            case EDoWhile(econd, e):
                doWhileLoop(econd, e);
                return null;
            case EFor(v, it, e):
                forLoop(v, it, e);
                return null;
            case EForGen(it, e):
                Tools.getKeyIterator(it, function(vk, vv, it) {
                    if (vk == null) {
                        curExpr = it;
                        error(ECustom("Invalid for expression"));
                        return;
                    }
                    forKeyValueLoop(vk, vv, it, e);
                });
                return null;
            case EBreak:
                throw SBreak;
            case EContinue:
                throw SContinue;
            case EReturn(e):
                returnValue = e == null ? null : expr(e);
                throw SReturn;
            case EFunction(params, fexpr, name, _):
                var capturedLocals = duplicate(locals);
                var me = this;
                var hasOpt = false, minParams = 0;
                for (p in params)
                    if (p.opt)
                        hasOpt = true;
                    else
                        minParams++;
                var f = function(args:Array<Dynamic>) {
                    if (((args == null) ? 0 : args.length) != params.length) {
                        if (args.length < minParams) {
                            var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
                            if (name != null)
                                str += " for function '" + name + "'";
                            error(ECustom(str));
                        }
                        // make sure mandatory args are forced
                        var args2 = [];
                        var extraParams = args.length - minParams;
                        var pos = 0;
                        for (p in params)
                            if (p.opt) {
                                if (extraParams > 0) {
                                    args2.push(args[pos++]);
                                    extraParams--;
                                } else
                                    args2.push(null);
                            } else
                                args2.push(args[pos++]);
                        args = args2;
                    }
                    var old = me.locals, depth = me.depth;
                    me.depth++;
                    me.locals = me.duplicate(capturedLocals);
                    for (i in 0...params.length)
                        me.locals.set(params[i].name, {r: args[i]});
                    var r = null;
                    var oldDecl = declared.length;
                    if (inTry)
                        try {
                            r = me.exprReturn(fexpr);
                        } catch (e:Dynamic) {
                            restore(oldDecl);
                            me.locals = old;
                            me.depth = depth;
                            #if neko
                            neko.Lib.rethrow(e);
                            #else
                            throw e;
                            #end
                        }
                    else
                        r = me.exprReturn(fexpr);
                    restore(oldDecl);
                    me.locals = old;
                    me.depth = depth;
                    return r;
                };
                var f = Reflect.makeVarArgs(f);
                if (name != null) {
                    if (depth == 0) {
                        // global function
                        setVar(name, f);
                    } else {
                        // function-in-function is a local function
                        declared.push({n: name, old: locals.get(name)});
                        var ref = {r: f};
                        locals.set(name, ref);
                        capturedLocals.set(name, ref); // allow self-recursion
                    }
                }
                return f;
            case EArrayDecl(arr):
                if (arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _))) {
                    var keys = [];
                    var values = [];
                    for (e in arr) {
                        switch (Tools.expr(e)) {
                            case EBinop("=>", eKey, eValue):
                                keys.push(expr(eKey));
                                values.push(expr(eValue));
                            default:
                                curExpr = e;
                                error(ECustom("Invalid map key=>value expression"));
                        }
                    }
                    return makeMap(keys, values);
                } else {
                    var a = new Array();
                    for (e in arr)
                        a.push(expr(e));
                    return a;
                }
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr))
                    return getMapValue(arr, index);
                return arr[index];
            case ENew(cl, params):
                var a = new Array();
                for (e in params)
                    a.push(expr(e));
                return cnew(cl, a);
            case EThrow(e):
                throw expr(e);
            case ETry(e, n, _, ecatch):
                var old = declared.length;
                var oldTry = inTry;
                try {
                    inTry = true;
                    var v:Dynamic = expr(e);
                    restore(old);
                    inTry = oldTry;
                    return v;
                } catch (err:Stop) {
                    inTry = oldTry;
                    throw err;
                } catch (err:Dynamic) {
                    // restore vars
                    restore(old);
                    inTry = oldTry;
                    // declare 'v'
                    declared.push({n: n, old: locals.get(n)});
                    locals.set(n, {r: err});
                    var v:Dynamic = expr(ecatch);
                    restore(old);
                    return v;
                }
            case EObject(fl):
                var o = {};
                for (f in fl)
                    set(o, f.name, expr(f.e));
                return o;
            case ETernary(econd, e1, e2):
                return if (expr(econd) == true) expr(e1) else expr(e2);
            case ESwitch(e, cases, def):
                var old:Int = declared.length;
                var val:Dynamic = expr(e);
                var match = false;
                for (c in cases) {
                    for (v in c.values) {
                        switch (Tools.expr(v)) {
                            case ECall(e, params):
                                switch (Tools.expr(e)) {
                                    case EField(_, f):
                                        var valStr:String = cast val;
                                        valStr = valStr.substring(0, valStr.indexOf("("));
                                        if (valStr == f) {
                                            var valParams = Type.enumParameters(val);
                                            for (i => p in params) {
                                                switch (Tools.expr(p)) {
                                                    case EIdent(n):
                                                        declared.push({
                                                            n: n,
                                                            old: {r: locals.get(n)}
                                                        });
                                                        locals.set(n, {r: valParams[i]});
                                                    default:
                                                }
                                            }
                                            match = true;
                                            break;
                                        }
                                    default:
                                }
                            default:
                                if (expr(v) == val) {
                                    match = true;
                                    break;
                                }
                        }
                    }
                    if (match) {
                        val = expr(c.expr);
                        break;
                    }
                }
                if (!match)
                    val = def == null ? null : expr(def);
                restore(old);
                return val;
            case EMeta(_, _, e):
                return expr(e);
            case ECheckType(e, _):
                return expr(e);
        }
        return null;
    }

    function doWhileLoop(econd, e) {
        var old = declared.length;
        do {
            if (!loopRun(() -> expr(e)))
                break;
        } while (expr(econd) == true);
        restore(old);
    }

    function whileLoop(econd, e) {
        var old = declared.length;
        while (expr(econd) == true) {
            if (!loopRun(() -> expr(e)))
                break;
        }
        restore(old);
    }

    function makeIterator(v:Dynamic):Iterator<Dynamic> {
        #if js
        // don't use try/catch (very slow)
        if (v is Array)
            return (v : Array<Dynamic>).iterator();
        if (v.iterator != null)
            v = v.iterator();
        #else
        #if (cpp) if (v.iterator != null) #end
        try
            v = v.iterator()
        catch (e:Dynamic) {};
        #end
        if (v.hasNext == null || v.next == null)
            error(EInvalidIterator(v));
        return v;
    }

    function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
        #if js
        // don't use try/catch (very slow)
        if (v is Array)
            return (v : Array<Dynamic>).keyValueIterator();
        if (v.keyValueIterator != null)
            v = v.keyValueIterator();
        #else
        try
            v = v.keyValueIterator()
        catch (e:Dynamic) {};
        #end
        if (v.hasNext == null || v.next == null)
            error(EInvalidIterator(v));
        return v;
    }

    function forLoop(n, it, e) {
        var old = declared.length;
        declared.push({n: n, old: locals.get(n)});
        var it = makeIterator(expr(it));
        while (it.hasNext()) {
            locals.set(n, {r: it.next()});
            if (!loopRun(() -> expr(e)))
                break;
        }
        restore(old);
    }

    function forKeyValueLoop(vk, vv, it, e) {
        var old = declared.length;
        declared.push({n: vk, old: locals.get(vk)});
        declared.push({n: vv, old: locals.get(vv)});
        var it = makeKeyValueIterator(expr(it));
        while (it.hasNext()) {
            var v = it.next();
            locals.set(vk, {r: v.key});
            locals.set(vv, {r: v.value});
            if (!loopRun(() -> expr(e)))
                break;
        }
        restore(old);
    }

    inline function loopRun(f:Void->Void) {
        var cont = true;
        try {
            f();
        } catch (err:Stop) {
            switch (err) {
                case SContinue:
                case SBreak:
                    cont = false;
                case SReturn:
                    throw err;
            }
        }
        return cont;
    }

    inline function isMap(o:Dynamic):Bool {
        return (o is IMap);
    }

    inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic {
        return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
    }

    inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void {
        cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
    }

    function makeMap(keys:Array<Dynamic>, values:Array<Dynamic>):Dynamic {
        var isAllString:Bool = true;
        var isAllInt:Bool = true;
        var isAllObject:Bool = true;
        var isAllEnum:Bool = true;
        for (key in keys) {
            isAllString = isAllString && (key is String);
            isAllInt = isAllInt && (key is Int);
            isAllObject = isAllObject && Reflect.isObject(key);
            isAllEnum = isAllEnum && Reflect.isEnumValue(key);
        }
        if (isAllInt) {
            var m = new Map<Int, Dynamic>();
            for (i => key in keys)
                m.set(key, values[i]);
            return m;
        }
        if (isAllString) {
            var m = new Map<String, Dynamic>();
            for (i => key in keys)
                m.set(key, values[i]);
            return m;
        }
        if (isAllEnum) {
            var m = new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
            for (i => key in keys)
                m.set(key, values[i]);
            return m;
        }
        if (isAllObject) {
            var m = new Map<{}, Dynamic>();
            for (i => key in keys)
                m.set(key, values[i]);
            return m;
        }
        error(ECustom("Invalid map keys " + keys));
        return null;
    }

    function get(o:Dynamic, f:String):Dynamic {
        if (o == null)
            error(EInvalidAccess(f));
        return {
            #if php
            // https://github.com/HaxeFoundation/haxe/issues/4915
            try {
                Reflect.getProperty(o, f);
            } catch (e:Dynamic) {
                Reflect.field(o, f);
            }
            #else
            Reflect.getProperty(o, f);
            #end
        }
    }

    function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o == null)
            error(EInvalidAccess(f));
        Reflect.setProperty(o, f, v);
        return v;
    }

    function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic {
        return call(o, get(o, f), args);
    }

    function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
        return Reflect.callMethod(o, f, args);
    }

    function cnew(cl:String, args:Array<Dynamic>):Dynamic {
        var c = Type.resolveClass(cl);
        if (c == null)
            c = resolve(cl);
        return Type.createInstance(c, args);
    }
}
