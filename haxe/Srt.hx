package haxe;

using StringTools;

/**
	Cross-platform Srt API.

	@see https://en.wikipedia.org/wiki/SubRip
**/
class Srt
{
	/**
	 * Stores the subtitle entries of the SRT file.
	 * The key (Int) represents the index/order of the subtitle.
	 * The value (SrtEntry) contains the actual subtitle text.
	 */
	public var contents:Map<Int, SrtEntry>;

    /**
     * Length of the Srt contents instance.
     */
    public var length:Int;

    public function new()
    {
        contents = new Map<Int, SrtEntry>();
        length = 0;
    }

    /**
     * Adds a subtitle entry at a specific index with its text and timecodes.
     */
    public function addContentByIndex(index:Int, content:String, startTime:Float, endTime:Float):Void
    {
        contents.set(index, {text: content, start: startTime, end: endTime});
        length++;
    }

    /**
     * Adds a subtitle entry at the next available index using its text and timecodes.
     */
    public function addContent(content:String, startTime:Float, endTime:Float):Void
    {
        addContentByIndex(length + 1, content, startTime, endTime);
    }

    /**
     * Parses a SRT timecode string (HH:MM:SS,ms) and returns milliseconds
     */
    public static function parseTimecode(timecode:String):Float
    {
        var parts = timecode.split(":");
        if (parts.length != 3)
            return 0;

        var hours = Std.parseInt(parts[0]);
        var minutes = Std.parseInt(parts[1]);

        var secParts = parts[2].split(",");
        var seconds = Std.parseInt(secParts[0]);
        var milliseconds = secParts.length > 1 ? Std.parseInt(secParts[1]) : 0;

        return (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds;
    }

    /**
     * Parses a full SRT-formatted string into an Srt instance
     */
    public static function parse(text:String):Srt
    {
        var srt:Srt = new Srt();

        var normalized:String = text.replace("\r\n", "\n").replace("\r", "\n");
        var blocks:Array<String> = normalized.split("\n\n");

        for (block in blocks)
        {
            if (block.trim() == "")
                continue;

            var lines = block.split("\n");

            if (lines.length >= 2)
            {
                var index = Std.parseInt(lines[0]);
                var timecodes = lines[1];
                var contentLines = lines.slice(2, lines.length);
                var content = contentLines.join("\n");

                var startTimeCode = timecodes.split(" --> ")[0];
                var endTimeCode = timecodes.split(" --> ")[1];

                srt.addContentByIndex(index, content, parseTimecode(startTimeCode), parseTimecode(endTimeCode));
            }
        }

        return srt;
    }

    /**
     * Returns an Srt that has been formatted into a string
     */
    public static function stringify(srt:Srt):String
    {
        var output:StringBuf = new StringBuf();

        for (index in 1...srt.length + 1)
        {
            var content:String = srt.contents.get(index).text;

            var startTime:Float = srt.contents.get(index).start;
            var endTime:Float = srt.contents.get(index).end;
            var startTimecode:String = Srt.formatTimecode(startTime);
            var endTimecode:String = Srt.formatTimecode(endTime);

            output.add('$index\n');
            output.add('$startTimecode --> $endTimecode\n');
            output.add('$content\n');

            if (index != srt.length)
                output.add('\n');
        }

        return output.toString();
    }

    /**
     * Converts milliseconds into a SRT timecode string ("HH:MM:SS,ms").
     */
    public static function formatTimecode(ms:Float):String
    {
        var totalSeconds = Math.floor(ms / 1000);
        var milliseconds = Std.int(ms % 1000);

        var hours = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = totalSeconds % 60;

        return StringTools.lpad(Std.string(hours), "0", 2) + ":" +
               StringTools.lpad(Std.string(minutes), "0", 2) + ":" +
               StringTools.lpad(Std.string(seconds), "0", 2) + "," +
               StringTools.lpad(Std.string(milliseconds), "0", 3);
    }


    /**
     * Returns a srt instance into a string
     */
    function toString():String
	{
		var output:StringBuf = new StringBuf();

		for (index in 1...length + 1)
		{
			var content = contents.get(index).text;
			var start = contents.get(index).start;
			var end = contents.get(index).end;

			if (content == null) continue;

			output.add('{[$index], "$content", (' + (end - start) + 'ms)}');
            if (index != length) output.add(', ');
		}

		return output.toString();
	}
}

typedef SrtEntry =
{
    var text:String;
    var start:Float;
    var end:Float;
}