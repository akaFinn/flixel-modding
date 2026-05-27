![](images/create.png?raw=true)
# How to Create modpacks flixel-modding

## 1. Initilize flixel-modding

After finishing the setup and initilizing `FlxModding`you can utilize functions in `FlxModding`.

```haxe
class Main extends Sprite
{
    public function new()
    {
        FlxModding.init();
        addChild(new FlxGame(0, 0, PlayState));
    }
}
```

## 2. Create modpacks

By using the `create` function found in `FlxModding` you can create your own modpacks with any metadata format you provide, along with what type of modpack you create.

Just be sure to call `create` **after** initilizing `FlxModding` otherwise your game will crash.

```haxe
class Main extends Sprite
{
    public function new()
    {
        FlxModding.init();
        addChild(new FlxGame(0, 0, PlayState));

		FlxModding.create("newMod", flixel.system.FlxModpack,
		{
			name: "My Mod!",
			prefix: "newMod",

			tags: ["new", "modding", "flixel"],
			description: "Brand new mod for new and awesome things",
			version: "1.2.3",

			credits: [
				{
					name: "John Doe",
					role: "Creator",
					links: [{title: "X", url: "https://x.com/X"}],
				}
			],

			priority: 1,
			enabled: true,
			links: [{title: "HaxeFlixel", url: "https://haxeflixel.com/"}],
		});
    }
}
```

After that, the create function should create the folder for the modpack, and from there you can edit it yourself by adding images, audio, data, you get the idea.

## More documentation
- [How to Setup flixel-modding](doc_setup.md)
- [How to Customize flixel-modding](doc_customize.md)
- [How to Migrate to flixel-modding](doc_migrate.md)
- [Back to Main Page](../README.md)