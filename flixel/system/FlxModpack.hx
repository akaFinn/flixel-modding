package flixel.system;

import flixel.system.FlxModding.CreditFormat;
import flixel.util.FlxStringUtil;
import sys.io.File;

class FlxModpack extends FlxBasic
{
    public var name:String;
    public var version:String;
    public var description:String;

    public var priority:Int;
    public var file:String;

    public var credits:Array<CreditFormat>;

    public function new(file:String)
    {
        this.file = file;
        this.ID = FlxModding.mods.length + 1;
        this.priority = FlxModding.mods.length + 1;

        super();
    }

    public function updateMetadata():Void
    {
        @:privateAccess
        File.saveContent(FlxModding.modsDirectory + "/" + file + "/" + FlxModding.metaDirectory, FlxModding.convertToString(
        {
            name: name,
            version: version,
            description: description,

            credits: credits,

            priority: priority,
            active: active,
        }));    
    }

    public function directory():String
    {
        @:privateAccess
        return FlxModding.modsDirectory + "/" + file;
    }

    override public function destroy():Void
    {
        super.destroy();
        FlxModding.remove(this);    
    }

    override public function toString():String
    {
        return FlxStringUtil.getDebugString([
			LabelValuePair.weak("name", name),
            LabelValuePair.weak("active", active),
            LabelValuePair.weak("alive", alive),
            LabelValuePair.weak("exists", exists)
		]);
    }
}