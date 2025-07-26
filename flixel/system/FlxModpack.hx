package flixel.system;

import flixel.system.FlxModding.CreditFormat;
import flixel.system.FlxModding.MetadataFormat;
import flixel.system.FlxModding.PolymodMetadataFormat;
import flixel.util.FlxStringUtil;

#if (!js || !html5)
import sys.io.File;
#end

enum FlxModpackType
{
    FLIXEL;
    POLYMOD; 
}

/**
 * Represents a single modpack instance that can be added to FlxModding.
 * Stores mod-related data and initialization behavior.
 */
class FlxModpack extends FlxBasic
{
    public var name:String;
    public var version:String;
    public var description:String;

    public var priority:Int;
    public var file:String;

    public var credits:Array<CreditFormat>;

    public var type:FlxModpackType;

    public function new(file:String)
    {
        this.file = file;
        this.ID = FlxModding.mods.length + 1;
        this.priority = FlxModding.mods.length + 1;

        super();
    }

    public function updateMetadata():Void
    {
        if (type == FLIXEL)
        {
            #if (!js || !html5)
            @:privateAccess
            File.saveContent(FlxModding.modsDirectory + "/" + file + "/" + FlxModding.metaDirectory, FlxModpack.toJsonString(
            {
                name: name,
                version: version,
                description: description,

                credits: credits,

                priority: priority,
                active: active,
            }));
            #end
        }
    }

    public function loadFromMetadata(metadata:MetadataFormat):FlxModpack
    {
        name = metadata.name;
        version = metadata.version;
        description = metadata.description;

        credits = metadata.credits;

        priority = metadata.priority;
        active = metadata.active;

        type = FLIXEL;

        return this;
    }

    public function directory():String
    {
        @:privateAccess
        return FlxModding.modsDirectory + "/" + file;
    }

    public function metaDirectory():String
    {
        @:privateAccess
        {
            switch (type)
            {
                case FLIXEL:
                    return directory() + "/" + FlxModding.metaDirectory;
                case POLYMOD:
                    return directory() + "/" + FlxModding.metaPolymodDirectory;
            }
        }  
    }

    public function iconDirectory():String
    {
        @:privateAccess
        {
            switch (type)
            {
                case FLIXEL:
                    return directory() + "/" + FlxModding.iconDirectory;
                case POLYMOD:
                    return directory() + "/" + FlxModding.iconPolymodDirectory;
            }
        }  
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

    /**
	 * Converts a `MetadataFormat` object into a readable JSON-formatted string.
	 * This is mainly used for saving modpack metadata into a `.json` file.
	 */
	public static function toJsonString(metadata:MetadataFormat):String
    {
        var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"name": "' + metadata.name + '",\n');
        buf.add('\t"version": "' + metadata.version + '",\n');
        buf.add('\t"description": "' + metadata.description + '",\n');
        buf.add('\n\t"credits": [\n');

        for (index in 0...metadata.credits.length) 
        {
            var credit = metadata.credits[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + credit.name + '",\n');
            buf.add('\t\t\t"title": "' + credit.title + '",\n');
            buf.add('\t\t\t"socials": "' + credit.socials + '"\n');
            buf.add('\t\t}');

            if (index < metadata.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"priority": ' + metadata.priority + ',\n');
        buf.add('\t"active": ' + metadata.active + '\n');
        buf.add('}');

        return buf.toString();
    }
}