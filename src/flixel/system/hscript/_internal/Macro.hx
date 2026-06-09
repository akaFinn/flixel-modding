package flixel.system.hscript._internal;

import flixel.system.hscript._internal.Expr.Error;
import flixel.system.hscript._internal.Expr.ErrorDef;
import haxe.macro.Expr;

class Macro {
    var p:Position;
    var binops:Map<String, Binop>;
    var unops:Map<String, Unop>;

    public function new(pos) {
        p = pos;
        binops = new Map();
        unops = new Map();
        for (c in Type.getEnumConstructs(Binop)) {
            if (c == "OpAssignOp")
                continue;
            var op = Type.createEnum(Binop, c);
            var assign = false;
            var str = switch (op) {
                case OpAdd:
                    assign = true;
                    "+";
                case OpMult:
                    assign = true;
                    "*";
                case OpDiv:
                    assign = true;
                    "/";
                case OpSub:
                    assign = true;
                    "-";
                case OpAssign: "=";
                case OpEq: "==";
                case OpNotEq: "!=";
                case OpGt: ">";
                case OpGte: ">=";
                case OpLt: "<";
                case OpLte: "<=";
                case OpAnd:
                    assign = true;
                    "&";
                case OpOr:
                    assign = true;
                    "|";
                case OpXor:
                    assign = true;
                    "^";
                case OpBoolAnd: "&&";
                case OpBoolOr: "||";
                case OpShl:
                    assign = true;
                    "<<";
                case OpShr:
                    assign = true;
                    ">>";
                case OpUShr:
                    assign = true;
                    ">>>";
                case OpMod:
                    assign = true;
                    "%";
                case OpAssignOp(_): "";
                case OpInterval: "...";
                case OpArrow: "=>";
                #if (haxe_ver >= 4)
                case OpIn: "in";
                #end
                default:
                    continue;
            };
            binops.set(str, op);
            if (assign)
                binops.set(str + "=", OpAssignOp(op));
        }
        for (c in Type.getEnumConstructs(Unop)) {
            var op = Type.createEnum(Unop, c);
            var str = switch (op) {
                case OpNot: "!";
                case OpNeg: "-";
                case OpNegBits: "~";
                case OpIncrement: "++";
                case OpDecrement: "--";
                #if (haxe_ver >= 4.2)
                case OpSpread: continue;
                #end
            }
            unops.set(str, op);
        }
    }

    function map<T, R>(a:Array<T>, f:T->R):Array<R> {
        var b = new Array();
        for (x in a)
            b.push(f(x));
        return b;
    }

    public function convertType(t:Expr.CType):ComplexType {
        return switch (t) {
            case CTOpt(t): 
                TOptional(convertType(t));
            case CTPath(pack, args):
                var params = [];
                if (args != null) {
                    for (t in args)
                        params.push(switch (t) {
                            case CTExpr(e): TPExpr(convertExpr(e));
                            default: TPType(convertType(t));
                        });
                }
                TPath({
                    pack: pack,
                    name: pack.pop(),
                    params: params,
                    sub: null,
                });
            case CTParent(t): 
                TParent(convertType(t));
            case CTFun(args, ret):
                TFunction(map(args, convertType), convertType(ret));
            case CTNamed(name, convertType(_) => ct):
                #if (haxe_ver >= 4)
                TNamed(name, ct);
                #else
                ct;
                #end
            case CTAnon(fields):
                var tf = [];
                for (f in fields) {
                    var meta = f.meta == null ? [] : [
                        for (m in f.meta)
                            {name: m.name, params: m.params == null ? [] : [for (e in m.params) convertExpr(e)], pos: p}
                    ];
                    tf.push({
                        name: f.name,
                        meta: meta,
                        doc: null,
                        access: [],
                        kind: FVar(convertType(f.t), null),
                        pos: p
                    });
                }
                TAnonymous(tf);
            case CTExpr(_):
                throw "assert";
        };
    }

    public function convertExpr(e:flixel.system.hscript._internal.Expr):Expr {
        return {
            expr: switch (e.e) {
                case EConst(c):
                    EConst(switch (c) {
                        case CInt(v): CInt(Std.string(v));
                        case CFloat(f): CFloat(Std.string(f));
                        case CString(s): CString(s);
                    });
                case EIdent(v):
                    EConst(CIdent(v));
                case EVar(n, t, e) | EFinal(n, t, e):
                    EVars([
                        {name: n, expr: if (e == null) null else convertExpr(e), type: if (t == null) null else convertType(t)}
                    ]);
                case EParent(e):
                    EParenthesis(convertExpr(e));
                case EBlock(el):
                    EBlock(map(el, convertExpr));
                case EField(e, f):
                    EField(convertExpr(e), f);
                case EBinop(op, e1, e2):
                    var b = binops.get(op);
                    if (b == null)
                        throw EInvalidOp(op);
                    EBinop(b, convertExpr(e1), convertExpr(e2));
                case EUnop(op, prefix, e):
                    var u = unops.get(op);
                    if (u == null)
                        throw EInvalidOp(op);
                    EUnop(u, !prefix, convertExpr(e));
                case ECall(e, params):
                    ECall(convertExpr(e), map(params, convertExpr));
                case EIf(c, e1, e2):
                    EIf(convertExpr(c), convertExpr(e1), e2 == null ? null : convertExpr(e2));
                case EWhile(c, e):
                    EWhile(convertExpr(c), convertExpr(e), true);
                case EDoWhile(c, e):
                    EWhile(convertExpr(c), convertExpr(e), false);
                case EFor(v, it, efor):
                    var p = #if (!macro) {file: p.file, min: e.pmin, max: e.pmax} #else p #end;
                    EFor({expr: EBinop(OpIn, {expr: EConst(CIdent(v)), pos: p}, convertExpr(it)), pos: p}, convertExpr(efor));
                case EForGen(it, efor):
                    EFor(convertExpr(it), convertExpr(efor));
                case EBreak:
                    EBreak;
                case EContinue:
                    EContinue;
                case EFunction(args, e, name, ret):
                    var targs = [];
                    for (a in args)
                        targs.push({
                            name: a.name,
                            type: a.t == null ? null : convertType(a.t),
                            opt: false,
                            value: null,
                        });
                    EFunction(#if haxe4 name != null ? FNamed(name, false) : FAnonymous #else name #end, {
                        params: [],
                        args: targs,
                        expr: convertExpr(e),
                        ret: ret == null ? null : convertType(ret),
                    });
                case EReturn(e):
                    EReturn(e == null ? null : convertExpr(e));
                case EArray(e, index):
                    EArray(convertExpr(e), convertExpr(index));
                case EArrayDecl(el):
                    EArrayDecl(map(el, convertExpr));
                case ENew(cl, params):
                    var pack = cl.split(".");
                    ENew({
                        pack: pack,
                        name: pack.pop(),
                        params: [],
                        sub: null
                    }, map(params, convertExpr));
                case EThrow(e):
                    EThrow(convertExpr(e));
                case ETry(e, v, t, ec):
                    ETry(convertExpr(e), [{type: convertType(t), name: v, expr: convertExpr(ec)}]);
                case EObject(fields):
                    var tf = [];
                    for (f in fields)
                        tf.push({field: f.name, expr: convertExpr(f.e)});
                    EObjectDecl(tf);
                case ETernary(cond, e1, e2):
                    ETernary(convertExpr(cond), convertExpr(e1), convertExpr(e2));
                case ESwitch(e, cases, edef):
                    ESwitch(convertExpr(e), [
                        for (c in cases)
                            {values: [for (v in c.values) convertExpr(v)], expr: convertExpr(c.expr)}
                    ], edef == null ? null : convertExpr(edef));
                case EMeta(m, params, esub):
                    var mpos = #if (!macro) {file: p.file, min: e.pmin, max: e.pmax} #else p #end;
                    EMeta({name: m, params: params == null ? [] : [for (p in params) convertExpr(p)], pos: mpos}, convertExpr(esub));
                case ECheckType(e, t):
                    ECheckType(convertExpr(e), convertType(t));
            },
            pos: #if (!macro) {file: p.file, min: e.pmin, max: e.pmax} #else p #end
        }
    }
}
