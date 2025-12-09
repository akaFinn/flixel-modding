package flixel.system.polymod;

#if !polymod
@:buildMetadata("_polymod_meta.json", "_polymod_icon.png")
#else
@:buildMetadata(polymod.PolymodConfig.modMetadataFile, polymod.PolymodConfig.modIconFile)
#end
class PolymodMetadataFormat extends FlxBaseMetadataFormat
{
    public var title:String;
    public var description:String;
	public var homepage:String;

    public var contributors:Array<PolymodCreditFormat> = [];

	public var api_version:String;
	public var mod_version:String;
	public var license:String;

	override public function toJsonString():String
	{
		var buf = new StringBuf();

        buf.add('{\n'); 
        buf.add('\t"title": "' + this.title + '",\n');
        buf.add('\t"description": "' + this.description + '",\n');
        buf.add('\t"homepage": "' + this.homepage + '",\n');
        buf.add('\n\t"contributors": [\n');

        for (index in 0...this.contributors.length) 
        {
            var contributor = this.contributors[index];
            buf.add('\t\t{\n');
            buf.add('\t\t\t"name": "' + contributor.name + '",\n');
            buf.add('\t\t\t"role": "' + contributor.role + '",\n');
            buf.add('\t\t\t"url": "' + contributor.url + '"\n');
            buf.add('\t\t}');

            if (index < this.contributors.length - 1)
            {
                buf.add(',\n\n');
            }
        }

        buf.add('\n\t],\n');
        buf.add('\n\t"api_version": "' + this.api_version + '",\n');
        buf.add('\t"mod_version": "' + this.mod_version + '",\n');
		buf.add('\t"license": "' + this.license + '"\n');
        buf.add('}');

        return buf.toString();
	}
}

typedef PolymodCreditFormat = 
{
    var name:String;
    var role:String;
    var url:String;
}