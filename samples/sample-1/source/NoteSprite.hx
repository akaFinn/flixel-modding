package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class NoteSprite extends FlxSprite
{
    public var timecode:Float;
    
    public function new(id:Int)
    {
        super();

        ID = id;
        var direction = Strumline.order[id];

        frames = FlxAtlasFrames.fromSparrow("assets/images/notes.png", "assets/images/notes.xml");
        animation.addByPrefix("note", "note" + direction, 24, false);
        animation.play("note", true);
        scale.set(0.7, 0.7);

        updateHitbox();
        centerOffsets();
    }
}