package flixel.system;

import haxe.semver.Version;

@:buildMetadata("_metadata.json", "_icon.png", "_config.ini")
class FlxMetadataFormat extends FlxBaseMetadataFormat
{
    public var name:String;
    public var prefix:String;

    public var api:Version;
    public var tags:Array<String>;
    public var description:String;
    public var version:Version;

    public var credits:Array<FlxCreditFormat>;

    public var priority:Int;
    public var enabled:Bool;
    public var links:Array<FlxLinkInstance>;

    override public function fromDynamic(data:Dynamic):FlxBaseMetadataFormat
    {
        if (Reflect.hasField(data, "api"))
            Reflect.deleteField(data, "api");

        this.api = FlxModding.VERSION;
        return super.fromDynamic(data);
    }

	override public function toJsonString():String
	{
		var buf = new StringBuf();

        buf.add('{\n'); 

        buf.add('\t"name": "' + this.name + '",\n');
        buf.add('\t"prefix": "' + this.prefix + '",\n');

        buf.add('\n\t"api": "' + this.api + '",\n');

        if (this.tags == null) {this.tags = [];}
        buf.add('\t"tags": [');

        for (index in 0...this.tags.length)
        {
            var tag = this.tags[index];

            buf.add('"' + tag + '"');
            if (index < this.tags.length - 1)
            {
                buf.add(', ');
            }
        }

        buf.add('],\n');

        buf.add('\t"description": "' + this.description + '",\n');
        buf.add('\t"version": "' + this.version + '",\n');

        if (this.credits == null) {this.credits = [];}
        buf.add('\n\t"credits": [\n');

        for (index in 0...this.credits.length) 
        {
            var credit = this.credits[index];

            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + credit.name + '",\n');
            buf.add('\t\t\t"role": "' + credit.role + '",\n');

            buf.add('\t\t\t"links": [');

            for (index in 0...credit.links.length)
            {
                var link = credit.links[index];

                buf.add('{"title": "' + link.title + '", "url": "' + link.url + '"}');
                if (index < credit.links.length - 1)
                {
                    buf.add(', ');
                }
            }

            buf.add(']\n');
            
            buf.add('\t\t}');

            if (index < this.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"priority": ' + this.priority + ',\n');
        buf.add('\t"enabled": ' + this.enabled + ',\n');

        if (this.links == null) {this.links = [];}
        buf.add('\t"links": [');

        for (index in 0...this.links.length)
        {
            var link = this.links[index];

            buf.add('{"title": "' + link.title + '", "url": "' + link.url + '"}');
            if (index < this.links.length - 1)
            {
                buf.add(', ');
            }
        }

        buf.add(']\n');

        buf.add('}');

        return buf.toString();
	}
}

@:buildMetadata("metadata.json", "picture.png")
class FlxLegacyMetadataFormat extends FlxBaseMetadataFormat
{
    public var name:String;
    public var version:String;
    public var description:String;

    public var credits:Array<FlxLegacyCreditFormat> = [];

    public var priority:Int;
    public var active:Bool;

	override public function toJsonString():String
	{
		var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"name": "' + this.name + '",\n');
        buf.add('\t"version": "' + this.version + '",\n');
        buf.add('\t"description": "' + this.description + '",\n');
        buf.add('\n\t"credits": [\n');

        for (index in 0...this.credits.length) 
        {
            var credit = this.credits[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + credit.name + '",\n');
            buf.add('\t\t\t"title": "' + credit.title + '",\n');
            buf.add('\t\t\t"socials": "' + credit.socials + '"\n');
            buf.add('\t\t}');

            if (index < this.credits.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"priority": ' + this.priority + ',\n');
        buf.add('\t"active": ' + this.active + '\n');
        buf.add('}');

        return buf.toString();
	}
}

typedef FlxLegacyCreditFormat = 
{
    var name:String;
    var title:String;
    var socials:String;
}

typedef FlxCreditFormat = 
{
    var name:String;
    var role:String;
    var links:Array<FlxLinkInstance>;
}

typedef FlxLinkInstance = 
{
    var title:String;
    var url:String;
}