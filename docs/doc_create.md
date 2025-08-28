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

        FlxModding.create("newMod", new BitmapData(128, 128), new FlxMetadataFormat().fromDynamicData({
	        name: "New Awesome Mod",
	        version: "1.2.3",
	        description: "This is a brand new mod for the world!",

	        credits: [
		        {
			        name: "your_name",
			        title: "What role you took in making the mod",
			        socials: "https://your-website.com"
		        }
	        ],

	        priority: 1,
	        active: true,
        }));
    }
}
```

After that, the create function should create the folder for the modpack, and from there you can edit it yourself by adding images, audio, data, you get the idea.

## More documentation
[How to Setup flixel-modding](doc_setup.md)

[How to Customize flixel-modding](doc_customize.md)