package flixel.system;

@:buildMetadata("metadata.json", "picture.png")
class FlxMetadataFormat extends FlxBaseMetadataFormat
{
	public var name:String;
	public var version:String;
	public var description:String;

	public var credits:Array<CreditFormat> = [];

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

	override public function fromDynamicData(data:Dynamic):FlxMetadataFormat
	{
		this.name = data.name;
		this.version = data.version;
		this.description = data.description;

		this.credits = data.credits;

		this.priority = data.priority;
		this.active = data.active;

		return this;
	}
}

typedef CreditFormat =
{
	var name:String;
	var title:String;
	var socials:String;
}
