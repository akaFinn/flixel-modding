package flixel.system;

class FlxModpack
{
    public var name:String;
    public var author:String;
    public var description:String;
    public var active:Bool;

    public var ID:Int;
    public var priority:Int;
    public var file:String;

    public function new(file:String)
    {
        this.file = file;

        this.ID = FlxModding.mods.length + 1;
        this.priority = FlxModding.mods.length + 1;
    }

    public function kill():Void
    {
        active = false;    
    }

    public function revive():Void
    {
        active = true;    
    }

    public function formDirectory():String
    {
        @:privateAccess
        return FlxModding.modsDirectory + "/" + file;    
    }
}