package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import haxe.Json;

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

class Strumline extends FlxSpriteGroup
{
    var arrows:Map<String, FlxSprite>;
    var notes:Array<NoteSprite> = [];

    public static var order:Array<String> = ["Left", "Down", "Up", "Right"];

    var chart:SongData;
    
    public function new(x:Float, y:Float)
    {
        super(x, y);

        arrows = new Map<String, FlxSprite>();

        for (direction in Strumline.order)
        {
            var arrow = new FlxSprite();
            arrow.frames = FlxAtlasFrames.fromSparrow("assets/images/noteStrumline.png", "assets/images/noteStrumline.xml");
            arrow.animation.addByPrefix("static", "static" + direction, 24, false);
            arrow.animation.addByPrefix("confirm", "confirm" + direction, 24, false);
            arrow.animation.addByPrefix("press", "press" + direction, 24, false);
            arrow.animation.play("static", true);
            arrow.ID = Lambda.count(arrows);
            arrow.scale.set(0.7, 0.7);

            arrow.updateHitbox();
            arrow.setPosition((160 * 0.7) * Lambda.count(arrows), 0);
            arrow.centerOffsets();
            arrow.centerOrigin();

            add(arrow);
            arrows.set(direction, arrow);
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        for (note in notes)
        {
            if (FlxG.sound.music != null)
            {
                note.y = (this.y + (arrows[order[note.ID]].height / 2) - (note.height / 2)) - ((FlxG.sound.music.time - note.timecode) * (0.45 * chart.scrollSpeed.hard));
            }
        }

        if (FlxG.keys.anyJustPressed([LEFT, A]))
            justPressed(arrows["Left"]);
        if (FlxG.keys.anyJustPressed([DOWN, S]))
            justPressed(arrows["Down"]);
        if (FlxG.keys.anyJustPressed([UP, W]))
            justPressed(arrows["Up"]);
        if (FlxG.keys.anyJustPressed([RIGHT, D]))
            justPressed(arrows["Right"]);

        if (FlxG.keys.anyJustReleased([LEFT, A]))
            justReleased(arrows["Left"]);
        if (FlxG.keys.anyJustReleased([DOWN, S]))
            justReleased(arrows["Down"]);
        if (FlxG.keys.anyJustReleased([UP, W]))
            justReleased(arrows["Up"]);
        if (FlxG.keys.anyJustReleased([RIGHT, D]))
            justReleased(arrows["Right"]);
    }

    public function loadChart(chartData:String):Void
    {
        chart = Json.parse(chartData);

        for (rawNote in chart.notes.hard)
        {
            var timecode:Float = rawNote.t;
            var direction:Int = Std.int(rawNote.d);

            if (direction < 4)
            {
                var arrow:FlxSprite = arrows[order[direction]];

                var note:NoteSprite = new NoteSprite(direction);
                note.setPosition((arrow.x - this.x) + (arrow.width / 2) - (note.width / 2), FlxG.height);
                note.timecode = timecode;
                add(note);

                notes.push(note);
            }
        }
    }

    function justPressed(arrow:FlxSprite):Void
    {
        var note:NoteSprite = getNearestNote(getNotes(arrow.ID), arrow);

        if (note != null && Math.abs(note.getGraphicMidpoint().y - arrow.getGraphicMidpoint().y) <= 160)
        {
            note.kill();
            arrow.animation.play("confirm", true);
            arrow.animation.onFinish.addOnce((name:String) -> 
            {
                if (name == "confirm")
                {
                    arrow.animation.play("press");
                    arrow.centerOffsets();
                    arrow.centerOrigin();
                }
            });

            PlayState.boyfriend.animation.play(order[note.ID].toLowerCase(), true);
            PlayState.updateBoyfriendOffsets();

            PlayState.health += 0.023;

            if (Math.abs(note.getGraphicMidpoint().y - arrow.getGraphicMidpoint().y) <= 45)
            {
                var splash:FlxSprite = new FlxSprite();
                splash.frames = FlxAtlasFrames.fromSparrow("assets/images/noteSplashes.png", "assets/images/noteSplashes.xml");
                splash.animation.addByPrefix('note1-0', 'note impact 1 blue', 24, false);
                splash.animation.addByPrefix('note2-0', 'note impact 1 green', 24, false);
                splash.animation.addByPrefix('note0-0', 'note impact 1 purple', 24, false);
                splash.animation.addByPrefix('note3-0', 'note impact 1 red', 24, false);
                splash.animation.addByPrefix('note1-1', 'note impact 2 blue', 24, false);
                splash.animation.addByPrefix('note2-1', 'note impact 2 green', 24, false);
                splash.animation.addByPrefix('note0-1', 'note impact 2 purple', 24, false);
                splash.animation.addByPrefix('note3-1', 'note impact 2 red', 24, false);
                splash.animation.play("note" + note.ID + "-" + FlxG.random.int(0, 1), true);
                splash.animation.onFinish.add((name:String) -> {splash.kill();});
                splash.updateHitbox();
                splash.x = arrow.x;
                splash.alpha = 0.6;

                splash.offset.set(splash.width * 0.3, splash.height * 0.3);

                add(splash);
            }
        }
        else
        {
            arrow.animation.play("press", true);

            PlayState.health -= (0.023 * 2);
        }

        arrow.centerOffsets();
        arrow.centerOrigin();
    }

    function justReleased(arrow:FlxSprite):Void
    {
        arrow.animation.play("static", true);

        arrow.centerOffsets();
        arrow.centerOrigin();
    }

    function getNotes(id:Int):Array<NoteSprite>
    {
        var result:Array<NoteSprite> = [];
        
        for (note in notes)
        {
            if (note.ID == id)
            {
                result.push(note);
            }
        }

        return result;
    }

    function getNearestNote(notes:Array<NoteSprite>, arrow:FlxSprite):NoteSprite
    {
        var nearestNote:NoteSprite = notes[0];
        var nearestDistance:Float = Math.abs(nearestNote.y - arrow.y);

        for (note in notes)
        {
            var distance:Float = Math.abs(note.y - arrow.y);
            if (distance < nearestDistance)
            {
                nearestNote = note;
                nearestDistance = distance;
            }
        }

        return nearestNote;
    }
}

typedef ScrollSpeed =
{
    var easy:Float;
    var normal:Float;
    var hard:Float;
    var erect:Float;
    var nightmare:Float;
}

typedef CameraFocusValue =
{
    var x:Float;
    var y:Float;
    var duration:Float;
    var ease:String;
    var char:Int;
}

typedef CameraZoomValue =
{
    var duration:Float;
    var ease:String;
    var zoom:Float;
    var mode:String;
}

typedef Event =
{
    var t:Float;
    var e:String;
    var v:Dynamic;
}

typedef Note =
{
    var t:Float;
    var d:Int;
    var l:Null<Int>;
}

typedef Notes =
{
    var easy:Array<Note>;
    var normal:Array<Note>;
    var hard:Array<Note>;
    var erect:Array<Note>;
    var nightmare:Array<Note>;
}

typedef SongData =
{
    var version:String;
    var scrollSpeed:ScrollSpeed;
    var events:Array<Event>;
    var notes:Notes;
}
