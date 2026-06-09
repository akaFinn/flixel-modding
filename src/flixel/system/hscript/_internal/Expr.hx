package flixel.system.hscript._internal;

enum Const {
    CInt(v:Int);
    CFloat(f:Float);
    CString(s:String, ?interpolated:Bool);
}

typedef Expr = {
    var e:ExprDef;
    var pmin:Int;
    var pmax:Int;
    var origin:String;
    var line:Int;
}

enum ExprDef {
    EConst(c:Const);
    EIdent(v:String);
    EVar(n:String, ?t:CType, ?e:Expr);
    EFinal(n:String, ?t:CType, ?e:Expr);
    EParent(e:Expr);
    EBlock(e:Array<Expr>);
    EField(e:Expr, f:String);
    EBinop(op:String, e1:Expr, e2:Expr);
    EUnop(op:String, prefix:Bool, e:Expr);
    ECall(e:Expr, params:Array<Expr>);
    EIf(cond:Expr, e1:Expr, ?e2:Expr);
    EWhile(cond:Expr, e:Expr);
    EFor(v:String, it:Expr, e:Expr);
    EBreak;
    EContinue;
    EFunction(args:Array<Argument>, e:Expr, ?name:String, ?ret:CType);
    EReturn(?e:Expr);
    EArray(e:Expr, index:Expr);
    EArrayDecl(e:Array<Expr>);
    ENew(cl:String, params:Array<Expr>);
    EThrow(e:Expr);
    ETry(e:Expr, v:String, t:Null<CType>, ecatch:Expr);
    EObject(fl:Array<{name:String, e:Expr}>);
    ETernary(cond:Expr, e1:Expr, e2:Expr);
    ESwitch(e:Expr, cases:Array<{values:Array<Expr>, expr:Expr}>, ?defaultExpr:Expr);
    EDoWhile(cond:Expr, e:Expr);
    EMeta(name:String, args:Array<Expr>, e:Expr);
    ECheckType(e:Expr, t:CType);
    EForGen(it:Expr, e:Expr);
}

typedef Argument = {
    name:String,
    ?t:CType,
    ?opt:Bool,
    ?value:Expr
};

typedef Metadata = Array<{name:String, params:Array<Expr>}>;

enum CType {
    CTPath(path:Array<String>, ?params:Array<CType>);
    CTFun(args:Array<CType>, ret:CType);
    CTAnon(fields:Array<{name:String, t:CType, ?meta:Metadata}>);
    CTParent(t:CType);
    CTOpt(t:CType);
    CTNamed(n:String, t:CType);
    CTExpr(e:Expr); // for type parameters only
}

class Error {
    public var e:ErrorDef;
    public var pmin:Int;
    public var pmax:Int;
    public var origin:String;
    public var line:Int;

    public function new(e, pmin, pmax, origin, line) {
        this.e = e;
        this.pmin = pmin;
        this.pmax = pmax;
        this.origin = origin;
        this.line = line;
    }

    public function toString():String {
        return Printer.errorToString(this);
    }
}

enum ErrorDef {
    EInvalidChar(c:Int);
    EUnexpected(s:String);
    EUnterminatedString;
    EUnterminatedComment;
    EInvalidPreprocessor(msg:String);
    EUnknownVariable(v:String);
    EInvalidProperty(v:String);
    EInvalidIterator(v:String);
    EInvalidOp(op:String);
    EInvalidAccess(f:String);
    ECustom(msg:String);
}

enum ModuleDecl {
    DPackage(path:Array<String>);
    DImport(path:Array<String>, ?everything:Bool, ?name:String);
    DUsing(path:Array<String>);
    DClass(c:ClassDecl);
    DTypedef(c:TypeDecl);
    DEnum(e:EnumDecl);
    DInterface(e:InterfaceDecl);
}

typedef ModuleType = {
    var name:String;
    var params:{}; // TODO : not yet parsed
    var meta:Metadata;
    var isPrivate:Bool;
}

typedef ClassDecl = {
    > ModuleType,
    var extend:Null<CType>;
    var implement:Array<CType>;
    var fields:Array<FieldDecl>;
    var staticFields:Array<FieldDecl>;
    var constructor:Null<FieldDecl>;
    var isAbstract:Bool;
    var isExtern:Bool;
    var isFinal:Bool;
}

typedef EnumDecl = {
    > ModuleType,
    var fields:Array<EnumFieldDecl>;
}

typedef EnumFieldDecl = {
    var name:String;
    var args:Array<EnumArgDecl>;
}

typedef EnumArgDecl = {
    var name:String;
    var type:Null<CType>;
}

typedef TypeDecl = {
    > ModuleType,
    var extensions:Array<CType>;
    var t:CType;
}

typedef InterfaceDecl = {
    > ModuleType,
    var extend:Array<CType>;
    var fields:Array<FieldDecl>;
    var isExtern:Bool;
    var isFinal:Bool;
}

typedef FieldDecl = {
    var name:String;
    var meta:Metadata;
    var kind:FieldKind;
    var access:Array<FieldAccess>;
}

enum FieldAccess {
    APublic;
    APrivate;
    AInline;
    AFinal;
    AOverride;
    AOverload;
    AAbstract;
    AStatic;
    AMacro;
}

enum FieldKind {
    KFunction(f:FunctionDecl);
    KVar(v:VarDecl);
}

enum VarProperty {
    PSet;
    PGet;
    PNull;
    PNever;
    PDefault;
    PDynamic;
}

typedef FunctionDecl = {
    var args:Array<Argument>;
    var expr:Expr;
    var ret:Null<CType>;
}

typedef VarDecl = {
    var expr:Null<Expr>;
    var type:Null<CType>;
    var get:Null<VarProperty>;
    var set:Null<VarProperty>;
}
