![](assets/images/logo_normal.png?raw=true)
### Design by [l0go](https://github.com/l0go)

## About
**flixel-modding** is a robust and easy-to-use modding system built specifically for **HaxeFlixel**. It is designed to help developers add straightforward mod support to their games. Whether you're looking to allow asset replacement or loading entirely new assets from mods, flixel-modding has you covered.

## Features
- Simple API for integrating mod support
- Support for replacing existing game assets
- Ability to load new assets from user-created mods
- Lightweight and easily extendable

## Requirements
- HaxeFlixel
- (Optional) HScript 2.6.0+

## Limitations
- You cannot use flixel-modding for JavaScript or HTML5 targets.

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
### Creating mods using FlxModding
```haxe
FlxModding.create("coolestMod", new BitmapData(128, 128), new FlxMetadataFormat().fromDynamicData({
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
}));
```
### Customizing FlxModding
```haxe
var customFileSystem:IFileSystem = new CoolFileSystem();
var customAssetSystem:IAssetSystem = new CoolAssetSystem();

var customAssetPath:String = "coolAssets";
var customModPath:String = "coolMods";

FlxModding.init(CoolModpack, CoolMetadataFormat, customFileSystem, customAssetSystem, customAssetPath, customModPath);
```
