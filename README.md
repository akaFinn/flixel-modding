![](assets/images/logo_normal.png?raw=true)
### Design by [l0go](https://github.com/l0go)
[![Discord Support](https://img.shields.io/discord/162395145352904705.svg?logo=discord)](https://discord.com/channels/162395145352904705/1367138149259673712)
### Flixel-Modding is still unfinished, if you find issues or bugs you can make an issue report on Github or find me in the Haxe discord server.
![](assets/images/construction.gif)

## About
**flixel-modding** is a robust and easy-to-use modding system built specifically for **HaxeFlixel**. It is designed to help developers add straightforward mod support to their games. Whether you're looking to allow asset replacement or loading entirely new assets from mods, flixel-modding has you covered.

## Features
- Simple API for integrating mod support
- Support for replacing existing game assets
- Ability to load new assets from user-created mods
- Lightweight and easily extendable

## Requirements
- HaxeFlixel 5.9.0+
- (Optional) HScript 2.6.0+

## Limitations
- You can only use flixel-modding for HaxeFlixel version **5.9.0 or above**.
- You cannot use flixel-modding for JavaScript or HTML5 targets. **I swear I'm working on that**
- You cannot use OpenFL's `Assets.hx` class for things like `getText` or `getBitmapData`. Any and all methods of getting Asset Data must be done through either Flixel's `AssetFrontEnd.hx`, which can be found in `FlxG.assets.getAsset`. Or, by using `FlxModding.system.getAsset` **Not sure about working on this one...**

## Intended Usage
flixel-modding is intended for developers of HaxeFlixel games who want to:
- Allow users to replace default game assets with their own
- Enable community content through custom mods
- Simplify the process of managing mod files and directories

## Tutorial
Install flixel-modding using haxelib:

```sh
haxelib install flixel-modding
```

Add the path and the library to your `project.xml`:

```xml
<assets path="mods" />
```
```xml
<haxelib name="flixel-modding" />
```

Before creating your `FlxGame` instance, initialize the modding system using the following code:

```haxe
FlxModding.init();
```

This sets up the modding environment and ensures all mod assets are ready before the game starts.

## Examples
### Initilizing FlxModding
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
### Loading assets after FlxModding as been initilized
```haxe
// Both of these methods for loading images work.
sprite.loadGraphic("images/haxeflixel.png");
sprite.loadGraphic("assets/images/haxeflixel.png");
```
### Creating mods using FlxModding
```haxe
FlxModding.create("coolMod", new BitmapData(64, 64, true, 0xFFFFFF),
{
	name: "Cool Awesome Mod",
	version: "1.2.3",
	description: "Cool mod made for cooler people. B)",

	credits: [
		{
			name: "akaFinn_",
			title: "Creator",
			socials: "https://x.com/akaFinn_"
		}
	],

	priority: 1,
	active: true,
});
```
### Customizing FlxModding
```haxe
var customMetaPath = "pack.json";
var customIconPath = "icon.png";

FlxModding.init(customMetaPath, customIconPath, "coolAssets", "coolMods");
```
