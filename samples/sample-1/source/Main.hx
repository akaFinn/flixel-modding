package;

import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.system.FlxMetadataFormat;
import flixel.system.FlxModding;
import lime.utils.Assets;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		FlxModding.init();
		FlxSprite.defaultAntialiasing = true;

		addChild(new FlxGame(0, 0, PlayState));

		/*FlxModding.create("pico", new FlxMetadataFormat().fromDynamic({
			name: "Pico Mod",
			prefix: "pico",

			tags: ["pico", "fnf", "asset"],
			description: "Replaces BF with PICO",
			version: "1.1.0",

			credits: [
				{
					name: "akaFinn_",
					role: "Creator",
					links: [{title: "X", url: "https://x.com/akaFinn_"}],
				},

				{
					name: "PhantomArcade",
					role: "Artist & Animator",
					links: [{title: "X", url: "https://x.com/PhantomArcade3K"}],
				}
			],

			priority: 1,
			enabled: true,
			links: [{title: "HaxeFlixel", url: "https://haxeflixel.com/"}],
		}));*/
	}
}
